
drop table chat_groups cascade constraints;
drop table chat_messages cascade constraints;
drop table chat_rooms cascade constraints;
drop table emojis cascade constraints;
drop table message_attachments cascade constraints;
drop table message_reactions cascade constraints;
drop table poll_answers cascade constraints;
drop table poll_votes cascade constraints;
drop table polls cascade constraints;
drop table room_members cascade constraints;
drop table uploaded_files cascade constraints;
drop table user_access_tokens cascade constraints;
drop table user_configs cascade constraints;
drop table user_credentials cascade constraints;
drop table users cascade constraints;
drop sequence configs_seed_seq;
drop sequence users_avatar_seq;


CREATE TABLE chat_rooms
  (
     id                  NUMBER(10, 0) GENERATED BY DEFAULT ON NULL AS IDENTITY START WITH 1000 CONSTRAINT rooms_pk PRIMARY KEY,
     custom_display_name VARCHAR2(255 CHAR),
     public_id           RAW(16) DEFAULT ON NULL SYS_GUID() CONSTRAINT rooms_publicid_uk UNIQUE,
     type                VARCHAR2(32 CHAR) CONSTRAINT rooms_type_check CHECK (type IN ('DIRECT', 'GROUP'))
  );

CREATE TABLE emojis
  (
     id        NUMBER(10, 0) GENERATED BY DEFAULT ON NULL AS IDENTITY START WITH 1000 CONSTRAINT emojis_pk PRIMARY KEY,
     data_text NVARCHAR2(8) NOT NULL,
     label     VARCHAR2(32 CHAR) NOT NULL CONSTRAINT emojis_label_uk UNIQUE
  );

CREATE SEQUENCE users_avatar_seq MINVALUE 1 MAXVALUE 9 CYCLE NOCACHE;

CREATE TABLE users
  (
     id         NUMBER(10, 0) GENERATED BY DEFAULT ON NULL AS IDENTITY START WITH 1000 CONSTRAINT users_pk PRIMARY KEY,
	 avatar_id	NUMBER(10, 0) DEFAULT ON NULL 0,
     first_name VARCHAR2(255 CHAR) NOT NULL,
     last_name  VARCHAR2(255 CHAR) NOT NULL,
     nickname   VARCHAR2(32 CHAR) NOT NULL CONSTRAINT users_nickname_uk UNIQUE CONSTRAINT users_nickname_check CHECK(REGEXP_LIKE(nickname, '^[a-z_0-9]+$'))
  );

CREATE TABLE chat_groups
  (
     id 	    NUMBER(10, 0) GENERATED BY DEFAULT ON NULL AS IDENTITY START WITH 1000 CONSTRAINT groups_pk PRIMARY KEY,
     join_code  VARCHAR2(15 CHAR) NOT NULL CONSTRAINT groups_code_uk UNIQUE CONSTRAINT groups_code_check CHECK(REGEXP_LIKE(join_code, '^[a-z_0-9]+$')),
     room_id    NUMBER(10, 0) NOT NULL CONSTRAINT groups_rooms_uk UNIQUE CONSTRAINT groups_rooms_fk REFERENCES chat_rooms
  );
  
CREATE TABLE room_members
  (
     id          NUMBER(10, 0) GENERATED BY DEFAULT ON NULL AS IDENTITY START WITH 1000 CONSTRAINT members_pk PRIMARY KEY,
     last_read   TIMESTAMP DEFAULT ON NULL systimestamp,
	 joined_at	 TIMESTAMP DEFAULT ON NULL systimestamp,
	 left_at	 TIMESTAMP,
     permissions VARCHAR2(32) DEFAULT ON NULL 'DEFAULT' CONSTRAINT members_permissions_check CHECK (permissions IN ('READONLY', 'DEFAULT', 'MODERATOR', 'ADMIN')),
     room_id     NUMBER(10, 0) NOT NULL CONSTRAINT members_rooms_fk REFERENCES chat_rooms,
     user_id     NUMBER(10, 0) NOT NULL CONSTRAINT members_users_fk REFERENCES users,
	 CONSTRAINT members_user_room_uk UNIQUE (user_id, room_id)
  );

CREATE INDEX members_rooms_fk_i ON room_members(room_id);

CREATE TABLE polls
  (
     id             NUMBER(10, 0) GENERATED BY DEFAULT ON NULL AS IDENTITY START WITH 1000 CONSTRAINT polls_pk PRIMARY KEY,
     question_text  VARCHAR2(255 CHAR) NOT NULL,
	 is_multichoice NUMBER(1, 0) NOT NULL,
	 created_at		TIMESTAMP DEFAULT ON NULL systimestamp,
	 expires_at		TIMESTAMP,
     author_id   	NUMBER(10, 0) NOT NULL CONSTRAINT polls_users_fk REFERENCES users
  );

CREATE TABLE chat_messages
  (
     id             NUMBER(10, 0) GENERATED BY DEFAULT ON NULL AS IDENTITY START WITH 1000 CONSTRAINT messages_pk PRIMARY KEY,
     content        VARCHAR2(2047 CHAR),
     message_status VARCHAR2(32 CHAR) CONSTRAINT messages_status_check CHECK(message_status IN ('SENDING', 'SENT')),
     sent_at        TIMESTAMP DEFAULT ON NULL systimestamp,
     member_id      NUMBER(10, 0) NOT NULL CONSTRAINT messages_members_fk REFERENCES room_members,
     poll_id        NUMBER(10, 0) CONSTRAINT messages_polls_fk REFERENCES polls
  );

CREATE TABLE poll_answers
  (
     id          NUMBER(10, 0) GENERATED BY DEFAULT ON NULL AS IDENTITY START WITH 1000 CONSTRAINT answers_pk PRIMARY KEY,
     answer_text VARCHAR2(255 CHAR) NOT NULL,
     poll_id     NUMBER(10, 0) NOT NULL CONSTRAINT answers_polls_fk REFERENCES polls
  );

CREATE TABLE message_reactions
  (
	 id          NUMBER(10, 0) GENERATED BY DEFAULT ON NULL AS IDENTITY START WITH 1000 CONSTRAINT reactions_pk PRIMARY KEY,
     message_id NUMBER(10, 0) NOT NULL CONSTRAINT reactions_messages_fk REFERENCES chat_messages,
     member_id  NUMBER(10, 0) NOT NULL CONSTRAINT reactions_members_fk REFERENCES room_members,
     emoji_id   NUMBER(10, 0) NOT NULL CONSTRAINT reactions_emojis_fk REFERENCES emojis,
     CONSTRAINT reactions_messages_members_uk UNIQUE (message_id, member_id)
  );

CREATE TABLE poll_votes
  (
	 id          NUMBER(10, 0) GENERATED BY DEFAULT ON NULL AS IDENTITY START WITH 1000 CONSTRAINT votes_pk PRIMARY KEY,
     voter_id  NUMBER(10, 0) NOT NULL CONSTRAINT votes_users_fk REFERENCES users,
     answer_id NUMBER(10, 0) NOT NULL CONSTRAINT votes_answers_fk REFERENCES poll_answers,
	 CONSTRAINT votes_users_answers_uk UNIQUE(voter_id, answer_id)
  );

CREATE TABLE uploaded_files
  (
     id          NUMBER(10, 0) GENERATED BY DEFAULT ON NULL AS IDENTITY START WITH 1000 CONSTRAINT files_pk PRIMARY KEY,
     checksum    VARCHAR2(255 CHAR) NOT NULL,
     content_type    VARCHAR2(255 CHAR) NOT NULL,
     name        VARCHAR2(255 CHAR) NOT NULL,
     size_bytes  NUMBER(19, 0) NOT NULL,
     type        VARCHAR2(32 CHAR) CONSTRAINT files_type_check CHECK(type IN ('IMAGE', 'AUDIO', 'VIDEO', 'OTHER')),
     uploaded_at TIMESTAMP DEFAULT ON NULL systimestamp,
     author_id   NUMBER(10, 0) CONSTRAINT files_users_fk REFERENCES users
  );

CREATE TABLE message_attachments
  (
     id         NUMBER(10, 0) GENERATED BY DEFAULT ON NULL AS IDENTITY START WITH 1000 CONSTRAINT attachments_pk PRIMARY KEY,
     file_id    NUMBER(10, 0) NOT NULL CONSTRAINT attachments_files_fk REFERENCES uploaded_files,
     message_id NUMBER(10, 0) NOT NULL CONSTRAINT attachments_messages_fk REFERENCES chat_messages
  );

CREATE TABLE user_access_tokens
  (
     token      RAW(16) DEFAULT ON NULL SYS_GUID(),
     created_at TIMESTAMP DEFAULT ON NULL systimestamp,
     user_id    NUMBER(10, 0) NOT NULL CONSTRAINT tokens_users_fk REFERENCES users,
     CONSTRAINT tokens_pk PRIMARY KEY (token)
  );

CREATE SEQUENCE configs_seed_seq MINVALUE 0 MAXVALUE 31 CYCLE;

CREATE TABLE user_configs
  (
     id                   NUMBER(10, 0) GENERATED BY DEFAULT ON NULL AS IDENTITY START WITH 1000 CONSTRAINT configs_pk PRIMARY KEY,
     accents_color        VARCHAR2(7 CHAR),
     background_color     VARCHAR2(7 CHAR),
     font_size_multiplier FLOAT DEFAULT 1,
     show_notifications   NUMBER(1, 0) NOT NULL,
     text_color_main      VARCHAR2(7 CHAR),
     text_color_user      VARCHAR2(7 CHAR),
	 random_seed		  NUMBER(4, 0) DEFAULT ON NULL 0,
     user_id              NUMBER(10, 0) NOT NULL CONSTRAINT configs_users_fk REFERENCES users CONSTRAINT configs_users_uk UNIQUE
  );

CREATE TABLE user_credentials
  (
     id            NUMBER(10, 0) GENERATED BY DEFAULT ON NULL AS IDENTITY START WITH 1000 CONSTRAINT creds_pk PRIMARY KEY,
     changed_at    TIMESTAMP DEFAULT ON NULL systimestamp,
     password_hash VARCHAR2(255 CHAR),
     user_id       NUMBER(10, 0) NOT NULL CONSTRAINT creds_users_fk REFERENCES users CONSTRAINT creds_users_uk UNIQUE
  );



INSERT INTO emojis (label, data_text) VALUES ('jamesmay', '🐢');
INSERT INTO emojis (label, data_text) VALUES ('heart', '❤️');
INSERT INTO emojis (label, data_text) VALUES ('snowman', '⛄️');
INSERT INTO emojis (label, data_text) VALUES ('smiley', '😃');
INSERT INTO emojis (label, data_text) VALUES ('blush', '😊');
INSERT INTO emojis (label, data_text) VALUES ('france_zip', '🥖');
INSERT INTO emojis (label, data_text) VALUES ('rainbow', '🌈');
INSERT INTO emojis (label, data_text) VALUES ('game', '🎮');
INSERT INTO emojis (label, data_text) VALUES ('police', '🍩');
INSERT INTO emojis (label, data_text) VALUES ('king_dong', '🦍');
INSERT INTO emojis (label, data_text) VALUES ('beers', '🍻');
INSERT INTO emojis (label, data_text) VALUES ('fries', '🍟');
INSERT INTO emojis (label, data_text) VALUES ('pierogas', '🥟');
INSERT INTO emojis (label, data_text) VALUES ('hush', '🤐');
INSERT INTO emojis (label, data_text) VALUES ('love', '😍');
INSERT INTO emojis (label, data_text) VALUES ('lie', '🤥');
INSERT INTO emojis (label, data_text) VALUES ('clown', '🤡');
INSERT INTO emojis (label, data_text) VALUES ('horizontal_italian', '🤏');
INSERT INTO emojis (label, data_text) VALUES ('winner', '🥇');
INSERT INTO emojis (label, data_text) VALUES ('teeth', '😁' );
INSERT INTO emojis (label, data_text) VALUES ('lmao', '😂');
INSERT INTO emojis (label, data_text) VALUES ('lmao_sideways', '🤣');
INSERT INTO emojis (label, data_text) VALUES ('hehe', '😄');
INSERT INTO emojis (label, data_text) VALUES ('xd', '😆');
INSERT INTO emojis (label, data_text) VALUES ('wink', '😉');
INSERT INTO emojis (label, data_text) VALUES ('tongue', '😋');
INSERT INTO emojis (label, data_text) VALUES ('cool', '😎' );
INSERT INTO emojis (label, data_text) VALUES ('devil', '😈');
INSERT INTO emojis (label, data_text) VALUES ('kiss', '😘');
INSERT INTO emojis (label, data_text) VALUES ('small_smile', '🙂');
INSERT INTO emojis (label, data_text) VALUES ('hande_hoch', '🤗');
INSERT INTO emojis (label, data_text) VALUES ('smh', '🤔');
INSERT INTO emojis (label, data_text) VALUES ('poker_face', '😐');
INSERT INTO emojis (label, data_text) VALUES ('no_face', '😶');
INSERT INTO emojis (label, data_text) VALUES ('eyeroll', '🙄');
INSERT INTO emojis (label, data_text) VALUES ('blood', '🩸');
INSERT INTO emojis (label, data_text) VALUES ('crab', '🦀');
INSERT INTO emojis (label, data_text) VALUES ('juan', '🐎');
INSERT INTO emojis (label, data_text) VALUES ('virus', '🦠');
INSERT INTO emojis (label, data_text) VALUES ('bin', '🗑');
	

COMMIT;