importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-messaging-compat.js");

// todo Copy/paste firebaseConfig from Firebase Console
const firebaseConfig = {
    apiKey: "AIzaSyDkImHd39IMfQNdytRVxFY3yhzQwcEwvrQ",
    authDomain: "mytherapypal.firebaseapp.com",
    databaseURL: "https://mytherapypal-default-rtdb.europe-west1.firebasedatabase.app",
    projectId: "mytherapypal",
    storageBucket: "mytherapypal.appspot.com",
    messagingSenderId: "159382536980",
    appId: "1:159382536980:web:ec2dcfab18de1498333801",
    measurementId: "G-BRSDP2FNM2"
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

// todo Set up background message handler