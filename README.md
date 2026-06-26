# SwiftUI Realtime SNS

A real-time SNS app built with SwiftUI, Firebase, and Metal shaders.

## Features

- Metal-based image filters  
- Real-time filter selection chips  
- Metal filters  
    • Normal  
    • Mono  
    • Sepia  
    • Invert  
- SwiftUI modern UI  
- Real-time feed updates with Firestore  
- Firebase Authentication  
- Image uploads with Firebase Storage  
- Real-time camera preview  
- Front / Back camera switch  
- Filter intensity control (Mono / Sepia)  
- Photo capture  
- Preview  
- Save to Photo Library  

## Screenshots

<p float="left">
  <img src="screenshots/feed.png" width="250" />
  <img src="screenshots/metalfilter.png" width="250" />
  <img src="screenshots/comments.png" width="250" />
</p>
<p align="left">
  <img src="screenshots/userpage.png" width="250" />
  <img src="screenshots/fullscreen.png" width="250" />
  <img src="screenshots/filter.png" width="250" />
</p>

## Tech Stack

- SwiftUI
- Metal  
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- AVFoundation
- AsyncImage  
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
## Metal Filters

This app uses custom Metal shaders instead of CoreImage filters.

Image filtering pipeline:

UIImage  
&ensp;→ CGImage   
&ensp;→ MTKTextureLoader  
&ensp;→ MTLTexture  
&ensp;→ Fragment Shader  
&ensp;→ UIImage  

Implemented filters:

- Normal
- Invert
- Mono
- Sepia  
  
## Future Improvements

- User Profile Screen
- Follow System
- Push Notifications
- Reply Threads
- Image Caching
- Front / Back Camera Switching
- Flash Support
- Filter Intensity Control
- Video Recording
- Additional Metal Filters

## Metal Camera Pipeline

Camera frames are processed through the following pipeline:

AVCaptureSession  
&ensp;→ CMSampleBuffer  
&ensp;→ CVPixelBuffer  
&ensp;→ CVMetalTexture  
&ensp;→ MTLTexture  
&ensp;→ Metal Fragment Shader  
&ensp;→ MTKView  

Real-time filters are rendered directly on the GPU using custom Metal shaders.

## Technical Challenges

### Camera Orientation

Resolved orientation inconsistencies between:

- Real-time camera preview
- Captured images
- Saved photos

by configuring AVCaptureConnection rotation settings and image orientation handling.

### Aspect Ratio Correction

Implemented aspect ratio compensation between camera textures and MTKView rendering using custom vertex shader uniforms.

### Metal Rendering Pipeline

Built a custom Metal rendering pipeline using:

- CVMetalTextureCache
- MTLTexture
- MTLRenderPipelineState
- Custom Fragment Shaders

to achieve real-time GPU image processing.

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
https://github.com/taka-sakamoto  
