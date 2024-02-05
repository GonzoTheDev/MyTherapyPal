import 'package:chatview/chatview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_therapy_pal/models/chat_history.dart'; // Adjust path as needed
import 'package:my_therapy_pal/models/theme.dart'; // Adjust path as needed
import 'dart:async'; // Import for StreamSubscription

class ChatScreen extends StatefulWidget {
  final String chatID;

  const ChatScreen({Key? key, required this.chatID}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  AppTheme theme = LightTheme();
  bool isDarkTheme = false;
  final db = FirebaseFirestore.instance;
  late String uid;
  late String otherUserID;
  late String fname;
  late String sname;
  late String otherUserFname;
  late String otherUserSname;
  late String userType;
  late String otherUserType;
  late String photoURL;
  late String otherUserPhotoURL;
  late String? email;
  late ChatUser currentUser;
  late ChatUser otherUser;
  late ChatController _chatController;
  bool _isChatControllerInitialized = false;
  late Chat chat;
  bool isLoading = true; 
  StreamSubscription<List<Message>>? _messagesSubscription;
  final Set<String> _displayedMessagesIds = <String>{}; // Track displayed messages to prevent duplicates


  @override
  void initState() {
    super.initState();
    initializeChat();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }

  Future<void> initializeChat() async {
    uid = FirebaseAuth.instance.currentUser!.uid;
    final userProfileDoc = await FirebaseFirestore.instance.collection('profiles').doc(uid).get();
    fname = userProfileDoc['fname'];
    sname = userProfileDoc['sname'];
    userType = userProfileDoc['userType'];
    email = FirebaseAuth.instance.currentUser!.email;
    photoURL = userProfileDoc['photoURL'];
    final chatDoc = await FirebaseFirestore.instance.collection('chat').doc(widget.chatID).get();
    var users = chatDoc['users'];
    if (users[0] == uid) {
      otherUserID = users[1];
    } else {
      otherUserID = users[0];
    }
    final otherUserProfileDoc = await FirebaseFirestore.instance.collection('profiles').doc(otherUserID).get();
    otherUserFname = otherUserProfileDoc['fname'];
    otherUserSname = otherUserProfileDoc['sname'];
    otherUserType = otherUserProfileDoc['userType'];
    otherUserPhotoURL = otherUserProfileDoc['photoURL'];
    
    currentUser = ChatUser(
      id: uid,
      name: '$fname $sname',
      profilePhoto: otherUserPhotoURL,
    );
    otherUser = ChatUser(
      id: otherUserID,
      name: '$otherUserFname $otherUserSname',
      profilePhoto: otherUserPhotoURL,
    );

    chat = Chat(
      chatID: widget.chatID,
      users: [currentUser, otherUser],
    );

    // Subscribe to the messages stream
    _messagesSubscription = chat.messagesStream.listen((List<Message> messages) {
      setState(() {
        var newMessages = messages.where((msg) => !_displayedMessagesIds.contains(msg.id)).toList();
        if (!_isChatControllerInitialized) {
          _chatController = ChatController(
            initialMessageList: newMessages,
            scrollController: ScrollController(),
            chatUsers: [currentUser, otherUser],
          );
          _isChatControllerInitialized = true;
        } else {
          for (var msg in newMessages) {
            _chatController.addMessage(msg);
          }
        }
        for (var msg in newMessages) {
          _displayedMessagesIds.add(msg.id);
        }
        isLoading = false;
      });
    });

    // Listen for typing status
    FirebaseFirestore.instance.collection('chat').doc(widget.chatID).snapshots().listen((snapshot) {
      var typingStatus = snapshot.data()?['typingStatus'];
      if (typingStatus != null && typingStatus[otherUserID] == true) {
        // Show typing indicator
        setState(() {
          _chatController.setTypingIndicator = true;
        });
      } else {
        // Hide typing indicator
        setState(() {
          _chatController.setTypingIndicator = false;
        });
      }
    });
  }

// Function to update the typing status of the current user
void updateUserTypingStatus(bool isTyping) {
  var chatDocRef = FirebaseFirestore.instance.collection('chat').doc(widget.chatID);
  String fieldPath = 'typingStatus.${FirebaseAuth.instance.currentUser!.uid}';
  chatDocRef.update({fieldPath: isTyping});

  // If isTyping is true, wait for 5 seconds then set it to false
  if (isTyping) {
    Future.delayed(const Duration(seconds: 5), () {
      // It's important to check if the user hasn't started typing again in the meantime
      // This could be done by keeping a timestamp or a flag that indicates the last typing action
      // For simplicity, this example does not implement such a mechanism
      chatDocRef.update({fieldPath: false});
    });
  }
}


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      // Body of the chat screen
      body: ChatView(
        currentUser: currentUser,
        chatController: _chatController,
        onSendTap: _onSendTap,
        featureActiveConfig: const FeatureActiveConfig(
          lastSeenAgoBuilderVisibility: true,
          receiptsBuilderVisibility: true,
          enableReactionPopup: false,
          enableSwipeToSeeTime: true,
          enableDoubleTapToLike: false,
          enableSwipeToReply: false,
        ),
        chatViewState: ChatViewState.hasMessages,
        chatViewStateConfig: ChatViewStateConfiguration(
          loadingWidgetConfig: ChatViewStateWidgetConfiguration(
            loadingIndicatorColor: theme.outgoingChatBubbleColor,
          ),
          onReloadButtonTap: () {},
        ),
        typeIndicatorConfig: TypeIndicatorConfiguration(
          flashingCircleBrightColor: theme.flashingCircleBrightColor,
          flashingCircleDarkColor: theme.flashingCircleDarkColor,
        ),
        appBar: ChatViewAppBar(
          elevation: theme.elevation,
          backGroundColor: theme.appBarColor,
          profilePicture: otherUserPhotoURL,
          backArrowColor: theme.backArrowColor,
          chatTitle: "$otherUserFname $otherUserSname",
          chatTitleTextStyle: TextStyle(
            color: theme.appBarTitleTextStyle,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.25,
          ),
        ),
        chatBackgroundConfig: ChatBackgroundConfiguration(
          messageTimeIconColor: theme.messageTimeIconColor,
          messageTimeTextStyle: TextStyle(color: theme.messageTimeTextColor),
          defaultGroupSeparatorConfig: DefaultGroupSeparatorConfiguration(
            textStyle: TextStyle(
              color: theme.chatHeaderColor,
              fontSize: 17,
            ),
          ),
          backgroundColor: theme.backgroundColor,
        ),
        sendMessageConfig: SendMessageConfiguration(
          imagePickerIconsConfig: ImagePickerIconsConfiguration(
            cameraIconColor: theme.cameraIconColor,
            galleryIconColor: theme.galleryIconColor,
          ),
          replyMessageColor: theme.replyMessageColor,
          defaultSendButtonColor: theme.sendButtonColor,
          replyDialogColor: theme.replyDialogColor,
          replyTitleColor: theme.replyTitleColor,
          textFieldBackgroundColor: theme.textFieldBackgroundColor,
          closeIconColor: theme.closeIconColor,
          textFieldConfig: TextFieldConfiguration(
            onMessageTyping: (status) {
              updateUserTypingStatus(true);
            },
            compositionThresholdTime: const Duration(seconds: 1),
            textStyle: TextStyle(color: theme.textFieldTextColor),
          ),
          micIconColor: theme.replyMicIconColor,
          voiceRecordingConfiguration: VoiceRecordingConfiguration(
            backgroundColor: theme.waveformBackgroundColor,
            recorderIconColor: theme.recordIconColor,
            waveStyle: WaveStyle(
              showMiddleLine: false,
              waveColor: theme.waveColor ?? Colors.white,
              extendWaveform: true,
            ),
          ),
        ),
        chatBubbleConfig: ChatBubbleConfiguration(
          outgoingChatBubbleConfig: ChatBubble(
            linkPreviewConfig: LinkPreviewConfiguration(
              backgroundColor: theme.linkPreviewOutgoingChatColor,
              bodyStyle: theme.outgoingChatLinkBodyStyle,
              titleStyle: theme.outgoingChatLinkTitleStyle,
            ),
            receiptsWidgetConfig:
                const ReceiptsWidgetConfig(showReceiptsIn: ShowReceiptsIn.all),
            color: theme.outgoingChatBubbleColor,
          ),
          inComingChatBubbleConfig: ChatBubble(
            linkPreviewConfig: LinkPreviewConfiguration(
              linkStyle: TextStyle(
                color: theme.inComingChatBubbleTextColor,
                decoration: TextDecoration.underline,
              ),
              backgroundColor: theme.linkPreviewIncomingChatColor,
              bodyStyle: theme.incomingChatLinkBodyStyle,
              titleStyle: theme.incomingChatLinkTitleStyle,
            ),
            textStyle: TextStyle(color: theme.inComingChatBubbleTextColor),
            onMessageRead: (message) {
              debugPrint('Message Read');
            },
            senderNameTextStyle:
                TextStyle(color: theme.inComingChatBubbleTextColor),
            color: theme.inComingChatBubbleColor,
          ),
        ),
        replyPopupConfig: ReplyPopupConfiguration(
          backgroundColor: theme.replyPopupColor,
          buttonTextStyle: TextStyle(color: theme.replyPopupButtonColor),
          topBorderColor: theme.replyPopupTopBorderColor,
        ),
        reactionPopupConfig: ReactionPopupConfiguration(
          shadow: BoxShadow(
            color: isDarkTheme ? Colors.black54 : Colors.grey.shade400,
            blurRadius: 20,
          ),
          backgroundColor: theme.reactionPopupColor,
        ),
        messageConfig: MessageConfiguration(
          messageReactionConfig: MessageReactionConfiguration(
            backgroundColor: theme.messageReactionBackGroundColor,
            borderColor: theme.messageReactionBackGroundColor,
            reactedUserCountTextStyle:
                TextStyle(color: theme.inComingChatBubbleTextColor),
            reactionCountTextStyle:
                TextStyle(color: theme.inComingChatBubbleTextColor),
            reactionsBottomSheetConfig: ReactionsBottomSheetConfiguration(
              backgroundColor: theme.backgroundColor,
              reactedUserTextStyle: TextStyle(
                color: theme.inComingChatBubbleTextColor,
              ),
              reactionWidgetDecoration: BoxDecoration(
                color: theme.inComingChatBubbleColor,
                boxShadow: [
                  BoxShadow(
                    color: isDarkTheme ? Colors.black12 : Colors.grey.shade200,
                    offset: const Offset(0, 20),
                    blurRadius: 40,
                  )
                ],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          imageMessageConfig: ImageMessageConfiguration(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            shareIconConfig: ShareIconConfiguration(
              defaultIconBackgroundColor: theme.shareIconBackgroundColor,
              defaultIconColor: theme.shareIconColor,
            ),
          ),
        ),
        profileCircleConfig: ProfileCircleConfiguration(
          profileImageUrl: currentUser.profilePhoto,
        ),
        repliedMessageConfig: RepliedMessageConfiguration(
          backgroundColor: theme.repliedMessageColor,
          verticalBarColor: theme.verticalBarColor,
          repliedMsgAutoScrollConfig: RepliedMsgAutoScrollConfig(
            enableHighlightRepliedMsg: true,
            highlightColor: Colors.pinkAccent.shade100,
            highlightScale: 1.1,
          ),
          textStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.25,
          ),
          replyTitleTextStyle: TextStyle(color: theme.repliedTitleTextColor),
        ),
        swipeToReplyConfig: SwipeToReplyConfiguration(
          replyIconColor: theme.swipeToReplyIconColor,
        ),
      ),
    );
  }

    

Future<void> _onSendTap(
    String message,
    ReplyMessage? replyMessage,
    MessageType messageType,
) async {
  try { 
    await chat.addMessage(message, currentUser.id);
    updateUserTypingStatus(false); 
  } catch (e) {
    print("Error sending message: $e");
  }
}


  void _onThemeIconTap() {
    setState(() {
      if (isDarkTheme) {
        theme = LightTheme();
        isDarkTheme = false;
      } else {
        theme = DarkTheme();
        isDarkTheme = true;
      }
    });
  }
  }
