package com.holytrinity.nerdchat.entity;

import com.holytrinity.nerdchat.model.ChatRoomType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
@Entity
public class ChatRoom {
    @Id
    @GeneratedValue
    private UUID id;

    private ChatRoomType type;
    private String customDisplayName;

    @OneToMany(mappedBy = "chatRoom")
    private List<ChatRoomMember> members;
    @OneToMany(mappedBy = "chatRoom")
    private List<ChatMessage> messages;
    @OneToOne(mappedBy = "chatRoom", optional = true, cascade = CascadeType.PERSIST, fetch = FetchType.EAGER)
    private ChatRoomGroupData groupData;

}
