# remindfully
Remindfully meditation app

## Shortcuts

### Send URL to Claude Mac

An Apple Shortcut compatible with **iOS** and **macOS** that sends a URL to the **Claude Mac** Telegram group.

**File:** `shortcuts/Send URL to Claude Mac.shortcut`

#### How it works

1. Receives a URL (via the Share Sheet in Safari or any app that can share URLs)
2. URL-encodes the link
3. Opens Telegram and navigates to the Claude Mac group with the URL pre-filled as the message text
4. You tap **Send** in Telegram to post it

#### Installation

1. Download `shortcuts/Send URL to Claude Mac.shortcut` to your iPhone, iPad, or Mac.
2. Tap/double-click the file — the Shortcuts app will open and prompt you to add it.
3. Tap **Add Shortcut**.

#### Usage

**From Safari (iOS / macOS):**
1. Open any webpage whose URL you want to share.
2. Tap the **Share** button.
3. Scroll down and select **Send URL to Claude Mac**.
4. Telegram opens with the URL ready to send to Claude Mac — tap **Send**.

**Note:** The shortcut uses the Telegram URL scheme `tg://resolve?domain=claudemac` to open the Claude Mac group directly. Ensure Telegram is installed and that `claudemac` matches the group's public username.

To find a group's public username in Telegram: open the group → tap the group name at the top → look for a **Username** or **Link** field (e.g. `t.me/claudemac`). If the group is private and has no public username, the admin can create an invite link instead, and the shortcut's **Open URL** action can be updated to use that link. To edit the shortcut, open it in the Shortcuts app → tap the three-dot (⋯) menu → find the **Open URL** action and replace `claudemac` with the correct username.
