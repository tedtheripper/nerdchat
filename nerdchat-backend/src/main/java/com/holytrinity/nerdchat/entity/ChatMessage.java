package com.holytrinity.nerdchat.entity;

import com.holytrinity.nerdchat.model.ChatMessageStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import javax.persistence.*;
import java.util.Date;
import java.util.List;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Table(name = "chat_messages")
public class ChatMessage {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @Column(length = 2047)
    private String content;

    @CreationTimestamp

    private Date sentAt;

    @Enumerated(EnumType.STRING)
    private ChatMessageStatus messageStatus;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "member_id", nullable = false, foreignKey = @ForeignKey(name = "messages_member_fk"))
    private ChatRoomMember chatRoomMember;

    @ManyToOne(fetch = FetchType.LAZY, cascade = CascadeType.ALL, optional = true)
    @JoinColumn(name = "poll_id", foreignKey = @ForeignKey(name = "messages_polls_fk"))
    private Poll messagePoll;


    @OneToMany(fetch = FetchType.LAZY, cascade = CascadeType.ALL, mappedBy = "chatMessage")
    private List<ChatMessageReaction> reactions;

}
