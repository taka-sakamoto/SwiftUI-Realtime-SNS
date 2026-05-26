# SwiftUI Realtime SNS

A real-time SNS app built with SwiftUI, Firebase, and Metal.  

## Features

- Firebase Authentication
- Firestore real-time feed updates
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
- Hero Animations
- User Name Persistence
- SNS-style Feed UI  
- Metal-based image filters  
- Filter preview selector  
- SwiftUI modern UI  

## Tech Stack

- SwiftUI
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- AVFoundation
- AsyncImage  
- Metal  
- MTKTextureLoader  

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
  <img src="screenshots/metalfilter.png" width="250" />
  <img src="screenshots/comments.png" width="250" />
</p>
<p align="left">
  <img src="screenshots/userpage.png" width="250" />
  <img src="screenshots/fullscreen.png" width="250" />
</p>

## Metal Filters

This app uses custom Metal shaders instead of CoreImage filters.

Implemented filters:
- Invert
- Mono
- Sepia
  
## Future Improvements

- User Profile Screen
- Follow System
- Push Notifications
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
