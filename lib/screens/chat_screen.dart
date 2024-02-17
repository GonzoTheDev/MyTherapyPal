import 'dart:typed_data';
import 'package:chatview/chatview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_therapy_pal/models/chat.dart'; 
import 'package:my_therapy_pal/models/theme.dart';
import 'package:my_therapy_pal/services/encryption/RSA/rsa.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart'; 

class ChatScreen extends StatefulWidget {
  final String chatID;

  const ChatScreen({Key? key, required this.chatID}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  // Initialize theme attributes
  AppTheme theme = LightTheme();
  bool isDarkTheme = false;

  // Initialize database instance
  final db = FirebaseFirestore.instance;

  // Declare chat users attributes
  late String uid;
  late String otherUserID;
  late String fname;
  late String sname;
  late String otherUserFname;
  late String otherUserSname;
  late String userType;
  late String otherUserType;
  late String userRSAKey;
  late String encryptedAESKey;
  late Uint8List decryptedAESKey;
  late String decryptedAESKeyString;
  late String photoURL;
  late String otherUserPhotoURL;
  late String? email;
  late ChatUser currentUser;
  late ChatUser otherUser;

  // Declare chat attributes and controller
  late Chat chat;
  late ChatController _chatController;
  bool _isChatControllerInitialized = false;
  StreamSubscription<List<Message>>? _messagesSubscription;
  bool isLoading = true; 
  final Set<String> _displayedMessagesIds = <String>{}; 
  bool ai = false;


  // Initialize the chat screen
  @override
  void initState() {
    super.initState();
    initializeChat();
  }

  // Dispose of the chat screen
  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }

  // Function to initialize chat messages
  Future<void> initializeChat() async {

    // Get the user's profile data
    uid = FirebaseAuth.instance.currentUser!.uid;
    final userProfileDoc = await FirebaseFirestore.instance.collection('profiles').doc(uid).get();
    fname = userProfileDoc['fname'];
    sname = userProfileDoc['sname'];
    userType = userProfileDoc['userType'];
    email = FirebaseAuth.instance.currentUser!.email;
    photoURL = userProfileDoc['photoURL'];

    // Obtain shared preferences.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Get the users private RSA key from shared preferences
    final String? privateKeyRSA = prefs.getString('privateKeyRSA');

    // Get the users belonging to a chat and determine the other users ID
    final chatDoc = await FirebaseFirestore.instance.collection('chat').doc(widget.chatID).get();
    var users = chatDoc['users'];
    var keys = chatDoc['keys'];
    if (users[0] == uid) {
      otherUserID = users[1];
    } else {
      otherUserID = users[0];
    }
    if (keys[uid] != null) {
      encryptedAESKey = keys[uid];
    } else {
      encryptedAESKey = '';
    }

    if(encryptedAESKey != ''){
      decryptedAESKeyString = RSAEncryption().decrypt(key: privateKeyRSA, message: encryptedAESKey);
      // Remove the brackets and split by comma
      List<String> byteStrings = decryptedAESKeyString.substring(1, decryptedAESKeyString.length - 1).split(", ");
      // Convert each substring to an integer and then to a Uint8List
      decryptedAESKey = Uint8List.fromList(byteStrings.map((s) => int.parse(s)).toList());
    }else{
      decryptedAESKey = Uint8List(0);
    }

    // Check if the other user is the AI chatbot, if so set ai to true
    if (otherUserID == 'ai-mental-health-assistant') {
      ai = true;
    }

    // Get the other user's profile data
    final otherUserProfileDoc = await FirebaseFirestore.instance.collection('profiles').doc(otherUserID).get();
    otherUserFname = otherUserProfileDoc['fname'];
    otherUserSname = otherUserProfileDoc['sname'];
    otherUserType = otherUserProfileDoc['userType'];
    otherUserPhotoURL = otherUserProfileDoc['photoURL'];
    
    // Create the current user and other user objects
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

    // Create a chat object
    chat = Chat(
      chatID: widget.chatID,
      users: [currentUser, otherUser],
      aesKey: decryptedAESKey,
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
      chatDocRef.update({fieldPath: false});
    });
  }
}

// Function to update the typing status of the AI chatbot
void updateAITypingStatus(bool isTyping) {
  var chatDocRef = FirebaseFirestore.instance.collection('chat').doc(widget.chatID);
  String fieldPath = 'typingStatus.${"ai-mental-health-assistant"}';
  chatDocRef.update({fieldPath: isTyping});
}

  // Build the chat screen
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: ChatView(

        // ChatView configuration
        currentUser: currentUser,
        chatController: _chatController,
        onSendTap: _onSendTap,

        // ChatView features configuration
        featureActiveConfig: const FeatureActiveConfig(
          lastSeenAgoBuilderVisibility: true,
          receiptsBuilderVisibility: true,
          enableReactionPopup: false,
          enableSwipeToSeeTime: true,
          enableDoubleTapToLike: false,
          enableSwipeToReply: false,
        ),

        // ChatView state & widget configuration
        chatViewState: ChatViewState.hasMessages,
        chatViewStateConfig: ChatViewStateConfiguration(
          loadingWidgetConfig: ChatViewStateWidgetConfiguration(
            loadingIndicatorColor: theme.outgoingChatBubbleColor,
          ),
          onReloadButtonTap: () {},
        ),

        // ChatView typing indicator configuration
        typeIndicatorConfig: TypeIndicatorConfiguration(
          flashingCircleBrightColor: theme.flashingCircleBrightColor,
          flashingCircleDarkColor: theme.flashingCircleDarkColor,
        ),

        // ChatView app bar configuration
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

        // ChatView style configuration
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

        // ChatView send message configuration
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

        // ChatView chat bubble configuration
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
              debugPrint('Message Read: ${message.id}');
              if (message.status != MessageStatus.read) {
                chat.updateMessageStatus(message.id, 'read'); 
              }
              
            },
            senderNameTextStyle:
                TextStyle(color: theme.inComingChatBubbleTextColor),
            color: theme.inComingChatBubbleColor,
          ),
        ),

        // ChatView reply popup configuration
        replyPopupConfig: ReplyPopupConfiguration(
          backgroundColor: theme.replyPopupColor,
          buttonTextStyle: TextStyle(color: theme.replyPopupButtonColor),
          topBorderColor: theme.replyPopupTopBorderColor,
        ),

        // ChatView reaction popup configuration
        reactionPopupConfig: ReactionPopupConfiguration(
          shadow: BoxShadow(
            color: isDarkTheme ? Colors.black54 : Colors.grey.shade400,
            blurRadius: 20,
          ),
          backgroundColor: theme.reactionPopupColor,
        ),

        // ChatView message configuration
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

        // ChatView profile circle configuration
        profileCircleConfig: ProfileCircleConfiguration(
          profileImageUrl: currentUser.profilePhoto,
        ),

        // ChatView replied message configuration
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

    
// Function to send a message
Future<void> _onSendTap(

  // Declare message variables
  String message,
  ReplyMessage? replyMessage,
  MessageType messageType,
) async {
  try { 

    // Send the message
    await chat.addMessage(message, currentUser.id);

    // If the message is sent by the AI chatbot, add the message to the chat
    if(ai){
      updateAITypingStatus(true);
      await chat.addAIMessage(message, currentUser.id);
    }

  } catch (e) {
    print("Error sending message: $e");
  } finally {

    // Update the typing status of the current user
    updateUserTypingStatus(false);

    // If the message is sent by the AI chatbot, update the typing status of the AI chatbot
    if(ai){
      updateAITypingStatus(false);
    }

  }
}

  // Function to handle the theme icon tap (to be implemented later)
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
