# SwiftUI Realtime SNS

A realtime SNS-style iOS application built with SwiftUI and Firebase.   

## Features

- Anonymous Authentication
- Realtime Firestore Updates
- Firebase Storage Image Upload
- Realtime Feed
- Like System
- Double Tap Like Gesture
- Haptic Feedback
- Fullscreen Image Viewer
- Pinch to Zoom
- Relative Timestamps
- Realtime Comments
- Comment Count Synchronization
- Comment Delete Function
- User Name Persistence
- SNS-style Feed UI  

## Tech Stack

- SwiftUI
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- AVFoundation
- AsyncImage

## Firestore Structure

```
posts
 └── postId
      ├── imageUrl
      ├── imagePath
      ├── userId
      ├── userName
      ├── likedBy
      ├── commentCount
      ├── createdAt
      └── comments
           └── commentId
                ├── text
                ├── userId
                ├── userName
                └── createdAt
```

## Screenshots

<p float="left">
  <img src="screenshots/feed.png" width="250" />
  <img src="screenshots/comments.png" width="250" />
  <img src="screenshots/fullscreen.png" width="250" />
</p>

## Future Improvements

- User Profile Screen
- Follow System
- Push Notifications
- Hero Animations
- Metal GPU Filters
- Realtime Image Effects
- Reply Threads
- Image Caching

## Setup

1. Clone this repository
2. Create a Firebase project
3. Add GoogleService-Info.plist
4. Enable:
   - Anonymous Authentication
   - Cloud Firestore
   - Firebase Storage
5. Run the app

## Author
Takayuki Sakamoto  
