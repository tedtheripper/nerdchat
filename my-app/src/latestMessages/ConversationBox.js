import React, { useContext, useState } from "react";
import ConversationItem from "./ConversationItem";
import SettingsBox from "./SettingsBox/SettingsBox";
import UserControlBox from "./userControlBox/UserControlBox";
import "./ConversationBox.css";
import "../common/scrollbar.css";
import { UserConfig, ChatContext } from "../context";
import JoinChat from "./JoinChat";

const ConversationBox = ({ updateConfig, setLastRead }) => {
  const cfg = useContext(UserConfig);
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [joinChatOpen, setJoinChatOpen] = useState(false);
  return (
    <React.Fragment>
      <div className="conversationBoxContainer">
        <div style={{ height: "69px" }}>
          <div
            id="appTitleBox"
            style={{
              backgroundColor: cfg.accentsColor,
              color: cfg.textColorMain,
              zIndex: "1",
              fontSize: "30px",
            }}
          >
            <div id="appTitleBoxText">Nerdchat</div>
          </div>
          <div id="textLatestMessages" style={{ color: cfg.textColorUser }}>
            Latest Messages{" "}
          </div>
        </div>
        {settingsOpen ? (
          <SettingsBox {...{ updateConfig, setSettingsOpen }} />
        ) : null}
        <div id="conversationsContainer">
          <ChatContext.Consumer>
            {({ chatRoomList, setActiveChatId }) => {
              return (
                <ConversationItem
                  {...{ chatRoomList, setActiveChatId, setLastRead }}
                />
              );
            }}
          </ChatContext.Consumer>
        </div>
        <div
          id="joinConversation"
          style={{ color: cfg.textColorUser }}
          onClick={(e) => {
            setJoinChatOpen(!joinChatOpen);
          }}
        >
          {" "}
          <div id="newChatsButton" datatext="New Chats ✎" />
        </div>
        <UserControlBox {...{ settingsOpen, setSettingsOpen }} />
        {joinChatOpen ? (
          <JoinChat {...{ joinChatOpen, setJoinChatOpen }} />
        ) : null}
      </div>
    </React.Fragment>
  );
};

export default ConversationBox;
