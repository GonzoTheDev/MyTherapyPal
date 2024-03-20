import 'dart:typed_data';
import 'package:chatview/chatview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_therapy_pal/models/chat.dart'; 
import 'package:my_therapy_pal/models/theme.dart';
import 'package:my_therapy_pal/screens/dashboard_screen.dart';
import 'package:my_therapy_pal/services/encryption/RSA/rsa.dart';
import 'package:my_therapy_pal/services/encryption/AES/encryption_service.dart';
import 'package:my_therapy_pal/services/generate_chat.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart'; 

class ChatScreen extends StatefulWidget {
  final String chatID;

  const ChatScreen({super.key, required this.chatID});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  // Initialize theme attributes
  AppTheme theme = LightTheme();
  bool isDarkTheme = false;

  // Initialize database instance
  final db = FirebaseFirestore.instance;

  // Create a new instance of the RSA encryption 
  final rsaEncryption = RSAEncryption();

  // Create a new instance of the AES encryption service
  final aesKeyEncryptionService = AESKeyEncryptionService();

  // Declare chat users attributes
  late String uid;
  late String otherUserID;
  late String fname;
  late String sname;
  late String otherUserFname;
  late String otherUserSname;
  late String userType;
  late String otherUserType;
  late String userRSAPubKey;
  late String encryptedAESKey;
  late Uint8List decryptedAESKey;
  late String decryptedAESKeyString;
  late String photoURL;
  late String otherUserPhotoURL;
  late String? email;
  late ChatUser currentUser;
  late ChatUser otherUser;
  late List<dynamic> currentUserClients = []; 
  bool isOtherUserAClient = false; 

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
    userRSAPubKey = userProfileDoc['publicRSAKey'];

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

    // Check if the other user is a client of the current user
    currentUserClients = userProfileDoc['clients'] ?? [];
    isOtherUserAClient = currentUserClients.contains(otherUserID);

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
      username: fname,
    );

    // Initialize _chatController safely
    setState(() {
      _chatController = ChatController(
        initialMessageList: [], // Initialize with an empty list or appropriate default
        scrollController: ScrollController(),
        chatUsers: [currentUser, otherUser],
      );
      _isChatControllerInitialized = true;
    });

    // Subscribe to the messages stream
    _messagesSubscription = chat.messagesStream.listen((List<Message> messages) {
      if (mounted) {
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
        });
      }
    });

    // Listen for typing status
    FirebaseFirestore.instance.collection('chat').doc(widget.chatID).snapshots().listen((snapshot) {
      var typingStatus = snapshot.data()?['typingStatus'];
      if (typingStatus != null && typingStatus[otherUserID] == true) {
        // Show typing indicator
        if (mounted) {
          setState(() {
            _chatController.setTypingIndicator = true;
          });
        }
      } else {
        // Hide typing indicator
        if (mounted) {
          setState(() {
            _chatController.setTypingIndicator = false;
          });
        }
      }
    });

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to add the other user as a client
  void _addClient() async {
    try {
      await FirebaseFirestore.instance.collection('profiles').doc(uid).update({
        'clients': FieldValue.arrayUnion([otherUserID])
      });
      setState(() => isOtherUserAClient = true);
    } catch (e) {
      print("Error adding client: $e");
    }
  }

  // Function to remove the other user as a client
  void _removeClient() async {
    try {
      await FirebaseFirestore.instance.collection('profiles').doc(uid).update({
        'clients': FieldValue.arrayRemove([otherUserID])
      });
      setState(() => isOtherUserAClient = false);
    } catch (e) {
      print("Error removing client: $e");
    }
  }

  // Function to issue an invoice (Placeholder for actual implementation)
  void _issueInvoice() {
    // TODO: Implement invoice issuing functionality here
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

  void _createNewAiChat() async {

    Future<String> aiChatId;

    // Before using `context` or calling `setState`, check if the widget is still mounted
    if (!mounted) return;

    // Disable the old AI chat by setting active to false
    await db.collection("chat").doc(chat.chatID).delete();

    // Disable the old AI chat messages by setting active to false
    await db.collection("messages").where('chatID', isEqualTo: chat.chatID).get().then((snapshot) {
      for (DocumentSnapshot ds in snapshot.docs){
        ds.reference.delete();
      }
    });

    // Generate an AES key for the ai chat room
    final aesKey = aesKeyEncryptionService.generateAESKey(32);

    // Encrypt the AES key with the public key
    final encryptedAESKey = rsaEncryption.encrypt(
      key: userRSAPubKey,
      message: aesKey.toString(),
    );

    // Generate a new chat with the ai chatbot
    aiChatId = GenerateChat(
      aesKey: aesKey,
      encryptedAESKey: encryptedAESKey,
      fname: fname,
      uid: uid,
    ).generateAIChat(); 


    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(
          builder: (context) => FutureBuilder<String>(
            future: aiChatId,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return const Text('Error');
              } else {
                return const AccountHomePage(initialIndex: 2);
                //return ChatScreen(chatID: snapshot.data!);
              }
            },
          ),
            ),
            (route) => false,
          );
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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 5),
          child: AppBar(
            elevation: theme.elevation,
            backgroundColor: theme.appBarColor,
            titleSpacing: 0, 
            title: Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 2), 
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(otherUserPhotoURL),
                    radius: 18, 
                  ),
                  const SizedBox(width: 8), 
                  Text(
                    "$otherUserFname $otherUserSname",
                    style: TextStyle(
                      color: theme.appBarTitleTextStyle,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 0.25,
                    ),
                  ),
                ],
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 2), 
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: theme.backArrowColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            actions: [
              if (userType == 'Admin' || userType == 'Therapist') _buildPopupMenu(),
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 2), 
                child: ai ? IconButton(
                  onPressed: () => _createNewAiChat(),
                  icon: Icon(
                    Icons.open_in_new,
                    color: theme.themeIconColor,
                  ),
                  tooltip: "Start a new ai chat.",
                ) : const SizedBox.shrink(), 
              ),
            ],
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
          allowRecordingVoice: false,
          enableCameraImagePicker: false,
          enableGalleryImagePicker: false,
          sendButtonIcon: const Icon(Icons.send),
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

  Widget _buildPopupMenu() {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert, color: Colors.black),
      onSelected: (item) => _handleMenuAction(item),
      itemBuilder: (context) => [
        if (!isOtherUserAClient)
          const PopupMenuItem<int>(
            value: 0,
            child: Text('Add Client'),
          ),
        if (isOtherUserAClient) ...[
          const PopupMenuItem<int>(
            value: 1,
            child: Text('Remove Client'),
          ),
          const PopupMenuItem<int>(
            value: 2,
            child: Text('Issue Invoice'),
          ),
        ],
      ],
    );
  }

  void _handleMenuAction(int item) {
    switch (item) {
      case 0:
        _addClient();
        break;
      case 1:
        _removeClient();
        break;
      case 2:
        _issueInvoice();
        break;
      default:
        break;
    }
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
    if (mounted) {
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
}
