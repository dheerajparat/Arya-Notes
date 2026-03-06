# Arya Notes

Arya Notes ek personal note-taking app hai jo private writing, quick capture, aur account-based sync ke liye design ki gayi hai. App ka focus simple note management ke saath privacy aur access control par hai, taaki user apne notes ko create, read, update, delete, aur multiple sessions ke beech manage kar sake.

## App Overview

Arya Notes users ko apne personal notes ko structured tareeke se save karne deta hai. App login ke baad user-specific note space open karta hai jahan notes list form mein dikhte hain, search kiye ja sakte hain, aur kisi bhi note ko detail screen par open karke edit ya delete kiya ja sakta hai.

## Main Features

- Email aur password ke through account create aur login.
- User-specific note collection, jahan har account ke notes alag rehte hain.
- New note add karne ke liye quick bottom sheet flow.
- Existing note ko open karke full detail view mein padhna.
- Note title aur content ko edit karke save karna.
- Note delete karne se pehle confirmation dialog.
- Search bar ke through title ya content se notes filter karna.
- Pull-to-refresh aur manual refresh action.
- Light aur dark theme support based on device theme.

## Privacy And Security

- App remote storage par save hone se pehle note fields ko encrypt karti hai.
- Har signed-in user ke liye notes isolated rehte hain.
- Mobile devices par app unlock gate available hai, jahan biometric ya device screen lock authentication ke baad hi app access milta hai.
- App background se resume hone par dubara unlock maang sakti hai, jisse shared device par privacy better rehti hai.

## Offline And Sync Behavior

- Notes local device par bhi store hote hain, isliye app cached data ke saath kaam kar sakti hai.
- Note add, edit, ya delete karte waqt agar remote sync fail ho jaye to change local level par preserve rehta hai.
- Pending items later sync ke liye mark hote hain.
- Notes list mein unsynced note par status dikhaya jata hai, jisse user ko pata rehta hai ki item abhi cloud tak nahi pahucha.

## Main Screens

### Login

User apne registered email aur password se sign in karta hai. Invalid credentials aur common auth issues ke liye feedback diya jata hai.

### Sign Up

Naya account banane ke liye email, password, aur confirm password flow diya gaya hai. Password mismatch aur weak password jaisi validation bhi hoti hai.

### Home

Home screen par notes list, search bar, refresh action, logout action, aur add note button milta hai. Yahi app ka primary workspace hai.

### Note Detail

Is screen par selected note ka full content, date, aur time dikhte hain. Yahin se note ko edit mode mein convert karke update ya permanently delete kiya ja sakta hai.

## Typical User Flow

1. User sign up ya login karta hai.
2. App unlock hone ke baad home screen open hoti hai.
3. User naya note add karta hai ya existing note open karta hai.
4. Notes ko search, edit, refresh, ya delete kiya ja sakta hai.
5. Local changes sync hone par data updated state mein maintain rehta hai.

## Best For

- Personal notes
- Daily reminders ya quick text capture
- Private note storage
- Users jo simple interface ke saath account-based access chahte hain

## Current Scope

Arya Notes abhi text-based notes par focused hai. App ka core experience note creation, secure access, local persistence, aur sync-oriented note management ke around built hai.
