// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
import { getAuth } from "firebase/auth";

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyC0evh__8PqccSFjAM6SlZo9Y8ikt2aL28",
  authDomain: "proyecto-u2-ad.firebaseapp.com",
  projectId: "proyecto-u2-ad",
  storageBucket: "proyecto-u2-ad.firebasestorage.app",
  messagingSenderId: "575085853946",
  appId: "1:575085853946:web:09b5efba34933b6e895d43",
  measurementId: "G-MLK4YJVL9W"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);
const auth = getAuth(app);

export { app, analytics, auth };
