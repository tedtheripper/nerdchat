package com.holytrinity.nerdchat.service;

import com.holytrinity.nerdchat.entity.ChatRoom;
import com.holytrinity.nerdchat.entity.ChatRoomGroupData;
import com.holytrinity.nerdchat.entity.ChatRoomMember;
import com.holytrinity.nerdchat.entity.User;
import com.holytrinity.nerdchat.model.BasicChatMessageDto;
import com.holytrinity.nerdchat.model.ChatRoomListEntry;
import com.holytrinity.nerdchat.model.ChatRoomType;
import com.holytrinity.nerdchat.model.MemberPermissions;
import com.holytrinity.nerdchat.model.rooms.CreateChatResult;
import com.holytrinity.nerdchat.repository.ChatMessageRepository;
import com.holytrinity.nerdchat.repository.ChatRoomGroupDataRepository;
import com.holytrinity.nerdchat.repository.ChatRoomMemberRepository;
import com.holytrinity.nerdchat.repository.ChatRoomRepository;
import com.holytrinity.nerdchat.utils.TrimUtils;
import javassist.NotFoundException;
import org.apache.commons.lang3.RandomStringUtils;
import org.apache.commons.text.RandomStringGenerator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.util.Pair;
import org.springframework.messaging.MessagingException;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class ChatRoomService {
    @Autowired
    private UserService _users;
    @Autowired
    private ChatMessageRepository _msgRepository;
    @Autowired
    private ChatRoomRepository _roomRepository;
    @Autowired
    private ChatRoomMemberRepository _memberRepository;
    @Autowired
    private ChatRoomGroupDataRepository _groupRepository;


    public String getChatRoomName(ChatRoom room, UUID userId) {
        if (room.getType() != ChatRoomType.DIRECT)
            return room.getCustomDisplayName();
        return _memberRepository.findFirstByChatRoom_IdAndUser_idNot(room.getId(), userId)
                .map(x -> x.getUser().getFirstName() + " " + x.getUser().getLastName())
                .orElse("Yourself");
    }

    public void setLastRead(ChatRoomMember member) {
        member.setLastRead(new Date());
        _memberRepository.save(member);
    }

    public List<ChatRoomListEntry> getUserChatRoomList(UUID userId) {
        return _memberRepository.findByUser_id(userId).stream()
                .sorted(Comparator.comparing(ChatRoomMember::getLastRead).reversed())
                .map(x -> {
                    var m = _msgRepository.findLastInChatRoom(x.getChatRoom().getId());
                    return new ChatRoomListEntry(
                            m.map(BasicChatMessageDto::from).orElseGet(() -> BasicChatMessageDto.builder().content("").sentAt(x.getLastRead()).build()),
                            getChatRoomName(x.getChatRoom(), userId),
                            x.getChatRoom().getId(),
                            x.getChatRoom().getType(),
                            x.getPermissions(),
                            _msgRepository.countByChatRoom_idAndSentAtAfter(x.getChatRoom().getId(), x.getLastRead()),
                                    x.getChatRoom().getType() == ChatRoomType.DIRECT ? "" : x.getChatRoom().getGroupData().getJoinCode());

                })
                .filter(Objects::nonNull)
                .collect(Collectors.toList());
    }

    public Optional<ChatRoom> findById(UUID roomId) {
        return _roomRepository.findById(roomId);
    }

    public Optional<ChatRoomMember> findRoomMember(UUID roomId, UUID userId) {
        return _memberRepository.findFirstByChatRoom_IdAndUser_id(roomId, userId);
    }


    public Optional<ChatRoomMember> getRoomMember(UUID roomId, User user, boolean create) {
        return findRoomMember(roomId, user.getId())
                .or(() -> {
                    if (!create)
                        return Optional.empty();
                    return Optional.of(_memberRepository.save(
                            ChatRoomMember.builder()
                                    .chatRoom(ChatRoom.builder().id(roomId).build())
                                    .user(user)
                                    .build()
                    ));
                });
    }

    public Pair<Boolean, ChatRoomMember> getRoomMemberCreated(UUID roomId, User user) {
        var found = findRoomMember(roomId, user.getId());
        return found.map(chatRoomMember -> Pair.of(false, chatRoomMember)).orElseGet(() -> Pair.of(true,
                _memberRepository.save(ChatRoomMember.builder()
                        .chatRoom(ChatRoom.builder().id(roomId).build())
                        .user(user)
                        .build())
        ));

    }

    public Optional<ChatRoomMember> getRoomMember(UUID roomId, UUID userId, boolean create) {
        return getRoomMember(roomId, User.builder().id(userId).build(), create);

    }

    public Pair<ChatRoomMember, ChatRoomMember> addToRoom(UUID roomId, User userA, User userB) {
        return Pair.of(getRoomMember(roomId, userA, true).orElseThrow(),
                getRoomMember(roomId, userB, true).orElseThrow());
    }

    public ChatRoom createDirectChat(User u1, User u2) {
        var users = u1.getId().equals(u2.getId()) ? List.of(u1) : List.of(u1, u2);
        var room = _roomRepository.save(
                ChatRoom.builder().type(ChatRoomType.DIRECT).build()
        );
        var members = users.stream().map(u -> ChatRoomMember.builder().permissions(MemberPermissions.ADMIN).user(u).chatRoom(room).build()).collect(Collectors.toList());
        _memberRepository.saveAll(members);
        room.setMembers(members);
        return room;
    }

    public Pair<CreateChatResult, Optional<ChatRoom>> createDirectChatByNickname(User user, String nickname) {

        try {
            var target = _users.findByNickname(nickname).orElseThrow();
            if (target.getId() == user.getId())
                throw new Exception("Can't add yourself");
            var existing = _roomRepository.findExistingChatRoomBetween(user.getId(), target.getId());
            var isNew = existing.isEmpty();
            var room = existing.orElseGet(() -> createDirectChat(user, target));
            return Pair.of(new CreateChatResult(room.getId(), isNew), isNew ? Optional.of(room) : Optional.empty());

        } catch (Exception e) {

        }
        return Pair.of(new CreateChatResult(), Optional.empty());
    }

    public Pair<CreateChatResult, Optional<ChatRoom>> createGroupChat(User user, String groupName) {
        var code = RandomStringUtils.randomAlphanumeric(6).toLowerCase();
        var data = ChatRoomGroupData.builder().joinCode(code).build();
        var room =
                ChatRoom.builder()
                        .customDisplayName(groupName)
                        .groupData(data)
                        .type(ChatRoomType.GROUP)
                        .build();
        data.setChatRoom(room);
        _roomRepository.save(room);
        var member = _memberRepository.save(
                ChatRoomMember.builder()
                        .chatRoom(room)
                        .permissions(MemberPermissions.ADMIN)
                        .user(user)
                        .build()
        );
        room.setMembers(List.of(member));
        return Pair.of(new CreateChatResult(room.getId(), true), Optional.of(room));
    }

    public CreateChatResult joinChatByCode(User user, String code) {
        var room = _roomRepository.findChatRoomByCode(code);
        return room.map(chatRoom -> new CreateChatResult(chatRoom.getId(), getRoomMemberCreated(chatRoom.getId(), user).getFirst())).orElseGet(CreateChatResult::new);
    }

    public String setChatroomCode(UUID roomId, String code) throws MessagingException {
        code = TrimUtils.sanitize(code);
        var room = _roomRepository.findById(roomId);
        if(room.isEmpty())
            throw new MessagingException("Room not found");
        if(code.length() < 3)
            throw new MessagingException("Invalid code");
        var group = _groupRepository.findFirstByJoinCode(code);
        if(group.isPresent() && !group.get().getChatRoom().getId().equals(roomId))
            throw new MessagingException("Code in use. Try another one.");
        String finalCode = code;
        room.ifPresent(r -> {
            var data = r.getGroupData();
            data.setJoinCode(finalCode);
            _groupRepository.save(data);
        });
        return code;
    }
}
