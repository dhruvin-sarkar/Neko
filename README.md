- [x] Akshat is working on the closing notch shuting down thing
- [ ] after that we will delegate different folders to clean up the code
- [ ] Getting voice recognition working
- [ ] Try and maybe get the notch at a better state with the ai notch 
- [ ] we are gona run scans from code rabbit sonarqube and aikido
- [ ] final polishing on the app fixing whatever fixed
- [ ] Documentation including watching the video
- [ ] Demo video with cap and akshats video editing
- [ ] final touches on the docs video and app
- [ ] making sure we tick all the boxes and not miss anything
- [ ] Final play testing and bug fixing
- [ ] keep notch turned off by default
- [ ] Edit guided tour with new features like the notch and the neko voice thing
- [ ] moving the paw in the nav pill up a little
- [ ] Move the cat typing to somehwere else so it doesnt block send button
- [ ] Microphone on bg working hey neko stuff


<h1 align="center">
  <br>
  <img src="https://github.com/dhruvin-sarkar/Neko/blob/main/readmeAssets/Neko.gif?raw=true" width=90%>
  <br>
  <br>
  Neko
  <br>
</h1>
<div align="center">
  
![Flutter](https://img.shields.io/badge/Made%20with-Flutter-2ec4b6)
![Firebase](https://img.shields.io/badge/Made%20with-Firebase-FFCA28)
 
Neko is the purr-fect (and honestly, the only) cat owner companion app you'll need. Feeding schedules, vet records, and mood tracking, all wrapped up with an AI cat companion and an Apple-inspired Dynamic Island overlay, because your cat deserves nothing less pawsome.
 
### Overview
</div>
Neko was born out of pure cat-astrophe, juggling five different apps just to remember feeding times, vet visits, and whether a mood swing meant something was actually wrong. So this app was created to bring it all together in one meow-nificent place, complete with an AI companion who talks back and guides you through it all.

<div align='center'>
  
## Features
 
</div>

<div align='center'>

  ### The Dynamic Island
 
</div>

Turns your phone's punch hole cutout into an always-on activity pill, Dynamic Island, but with claws.
 
- ***Music Playback*** album art, track info, playback controls
- ***Calls & Navigation*** incoming calls, active directions, no cat-terruptions missed
- ***Downloads & Notifications*** mirrors system notifications live
- ***Feeding Timers*** countdowns so mealtime's never a cat-astrophe
- ***Voice Assistant*** voice chat, right in the notch
- ***Dual-Engine Machina*** *(/ref)* separate overlay engine, keeps purring after app close

<div align='center'>

  ### Core Features
 
</div>

- ***AI Chat*** purr-sonal chats with full history
- ***Voice Recognition*** "Hey Neko" wake word, background listening
- ***Cat Profiles*** purr-files for as many cats as you can herd
- ***Document Management*** vet records, digital pet passports
- ***Photo Capture & Gallery*** fur-tographs, synced via Firebase
- ***Guided Onboarding*** Duolingo-style walkthrough
- ***Animations*** Lottie cat states + custom NekoMotion transitions
- ***Keyboard Cat*** a little easter egg, because why not
- ***Settings*** themes, sounds, feature toggles, Notch on/off
  
<table align="center">
  <tr>
    <th>Cat Profile</th>
    <th>Adding a New Cat</th>
  </tr>
  <tr>
    <td><img src="https://github.com/dhruvin-sarkar/Neko/blob/main/readmeAssets/CatProfile.gif?raw=true" width=300px></td>
    <td><img src="https://github.com/dhruvin-sarkar/Neko/blob/main/readmeAssets/NewCat.gif?raw=true" width=300px></td>
  </tr>
</table>
<table align="center">
  <tr>
    <th>AI Capabilities</th>
    <th>The Dynamic Island</th>
  </tr>
  <tr>
    <td><img src="https://github.com/dhruvin-sarkar/Neko/blob/main/readmeAssets/AI%20Chat.gif?raw=true" width=300px></td>
    <td><img src="https://github.com/dhruvin-sarkar/Neko/blob/main/readmeAssets/Notch.gif?raw=true" width=300px></td>
  </tr>
</table>

<div align='center'>
  
### Tech Stack
 
</div>

- ***Flutter*** the framework holding this whole cat-tastrophe together
- ***Firebase*** Authentication, Firestore, and Storage
- ***Android native overlay service*** dual-engine implementation powering the Dynamic Island
- ***Lottie*** in-app animations
- ***Material 3*** component system
- 
<div align='center'>
  
## Prerequisites

</div>

Before you can let the cat out of the bag, make sure you have:
 
- ***Flutter SDK*** (3.x or later) — [installation guide](https://docs.flutter.dev/get-started/install)
- ***Dart SDK*** (included with Flutter)
- ***Android Studio***, with:
  - Android SDK (API level 26 or higher)
  - An emulator or physical Android device, physical device strongly recommended for testing the Notch overlay
- ***A Firebase project***, with the following enabled:
  - Authentication (Google Sign-In provider)
  - Cloud Firestore
## Running the Project
 
1. Clone the repo, no cat-burglary required:
```
   git clone https://github.com/dhruvin-sarkar/Neko.git
   cd neko
```
2. Install dependencies:
```
   flutter pub get
```
3. Add your Firebase configuration files (see Configuration below).
4. Run the app on a connected device or emulator:
```
   flutter run
```
5. To build a release APK:
```
   flutter build apk --release
```
 
## Configuration
 
A few things need to be set up before the app will actually purr to life:
 
| Configuration | Purpose | Where to set it |
|---|---|---|
| `google-services.json` | Firebase project credentials for Android | Place in `android/app/` |
| HC AI API key | Powers the AI chat and voice assistant | Add to `.env` at the project root as `AI_API_KEY=your_key_here` |
| Google Sign-In OAuth client ID | Required for authentication | Configure in the Firebase console under Authentication → Sign-in method, then update `android/app/build.gradle` with the matching SHA-1 fingerprint |
| Dynamic Island overlay permission | Enables the system-level overlay | Requested at runtime, can be toggled on/off from in-app Settings |
| Notification permission | Enables Neko to read your notifications for the Dynamic Island | Requested at runtime |
 
After adding Firebase config files and the `.env` entry, run `flutter clean && flutter pub get` before your next build so everything's purr-fectly in sync.
 
# Thanks fur checking out Neko!
 
</div>
