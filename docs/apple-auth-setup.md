# Apple ID ログイン設定手順

## 1. Apple Developer Portal（developer.apple.com）

### App ID設定
1. Certificates, Identifiers & Profiles → Identifiers
2. Bundle ID `com.gijiroku.app` を選択
3. Capabilities → **Sign In with Apple** を有効化

### Service ID作成
1. Identifiers → 「+」ボタン → **Services IDs** を選択
2. Description: `議事録アプリ Sign In`
3. Identifier: `com.gijiroku.app.signin`
4. Sign In with Apple を有効化
5. Configure:
   - Domains: `mbhcyaocfngegssvtdgl.supabase.co`
   - Return URLs: `https://mbhcyaocfngegssvtdgl.supabase.co/auth/v1/callback`

### Key作成
1. Keys → 「+」ボタン
2. Key Name: `Gijiroku Auth Key`
3. **Sign In with Apple** にチェック → Configure → App ID: `com.gijiroku.app`
4. ダウンロード → `.p8` ファイルを保管（Key IDを記録）

## 2. Supabase Dashboard

1. Authentication → Providers → **Apple** を有効化
2. 以下を入力:
   - **Client ID (Service ID)**: `com.gijiroku.app.signin`
   - **Secret Key**: `.p8` ファイルの内容
   - **Key ID**: Apple Developer で取得したKey ID
   - **Team ID**: Apple Developer アカウントのTeam ID

## 3. 確認事項

- iOSアプリのEntitlements (`GijirokuApp.entitlements`) に `com.apple.developer.applesignin` が設定済み
- AuthService.swift で `signInWithIdToken` を使用（nonce検証付き）
- SupabaseクライアントがApple providerをサポート

## 注意
- `.p8` ファイルは再ダウンロード不可。安全な場所に保管
- Service IDとApp ID（Bundle ID）は異なるもの
- iOSネイティブのSign In with Appleでは、Service IDではなくApp IDが使用される
