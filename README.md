# My Dotfiles

これは、[chezmoi](https://chezmoi.io/)で管理されている個人のdotfilesリポジトリです。

## 新しいPCへのセットアップ手順

1.  **Homebrewのインストール**:

    macOSのパッケージマネージャーであるHomebrewをインストールします。

    ```bash
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ```

2.  **このリポジトリのクローン**:

    dotfilesを管理しているこのリポジトリを、適切な場所にクローンします。

    ```bash
    git clone https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git ~/.local/share/chezmoi
    ```
    **注**: `YOUR_USERNAME/YOUR_REPOSITORY.git`の部分は、ご自身のGitHubリポジトリのURLに置き換えてください。

3.  **各種ツールのインストール**:

    `Brewfile`を使って、`chezmoi`自身を含む必要なツールを一括でインストールします。

    ```bash
    brew bundle --file=~/.local/share/chezmoi/Brewfile
    ```

4.  **dotfilesの適用**:

    以下のコマンドで、リポジトリ内の設定をホームディレクトリに反映させます。スクリプトが実行され、必要な設定が自動的に行われます。

    ```bash
    chezmoi apply
    ```

## 1Password連携

この設定では、Gitの認証情報のような機密情報を[1Password](https://1password.com/)で管理します。

1.  **1Passwordへのサインイン**:

    `Brewfile`で1Password CLIはインストール済みです。以下のコマンドでアカウントにサインインしてください。

    ```bash
    op signin
    ```

2.  **機密情報アイテムの作成**:

    "Private"ボルトに"git"という名前でアイテムを作成し、以下のフィールドを追加します。
    - `name`: あなたのGitでの名前
    - `email`: あなたのGitでのメールアドレス

    以下のコマンドでも作成できます。

    ```bash
    op item create --category "Secure Note" --title "git" --vault "Private" 'name[text]=YOUR_GIT_NAME' 'email[text]=YOUR_GIT_EMAIL'
    ```
    **注**: `YOUR_GIT_NAME`と`YOUR_GIT_EMAIL`は、ご自身の情報に置き換えてください。

3.  再度`chezmoi apply`を実行すると、`.gitconfig`に1Passwordから取得した認証情報が反映されます。

## chezmoiのTipsとよく使うコマンド

### dotfilesの更新を反映する

日々の運用でdotfilesを変更・更新する方法です。

#### 1. リポジトリの変更をローカルに反映する

他のPCで加えた変更を現在のPCに反映させたい場合や、GitHub上で直接編集した内容を取り込みたい場合は、`update`コマンドを使います。これは内部で`git pull`を実行し、変更があれば`chezmoi apply`まで自動で行ってくれます。

```bash
chezmoi update
```

#### 2. ローカルでの変更をリポジトリに反映する

- **設定ファイルの編集**:
  `chezmoi`で管理しているファイルを編集するには`edit`コマンドが便利です。

  ```bash
  # ~/.zshrcを編集したい場合
  chezmoi edit ~/.zshrc
  ```
  編集後、`chezmoi apply`で変更をシステムに反映させるのを忘れないでください。

- **変更をGitにコミット**:
  `edit`や`add`で加えた変更は、`chezmoi`のソースディレクトリ（`~/.local/share/chezmoi`）に保存されています。これらの変更を`git`でコミットし、GitHubにプッシュすることで、他の環境にも同期できるようになります。

  ```bash
  cd $(chezmoi source-path)
  git add .
  git commit -m "変更内容のメッセージ"
  git push
  ```

### `brew`でパッケージをインストール・アンインストールした場合

`Brewfile`を更新して、新しいパッケージを管理に含めたい場合の手順です。

1.  `brew`でパッケージをインストール、またはアンインストールします。
2.  以下のコマンドで`Brewfile`を更新します。

    ```bash
    brew bundle dump --global --force
    ```
    **注**: `--global`フラグをつけることで、`~/.Brewfile`ではなく、`chezmoi`で管理している`Brewfile`に直接書き込みます。

3.  `chezmoi`に`Brewfile`の変更をコミットします。

### `.zshrc`などを直接編集してしまった場合

`chezmoi edit`を使わずに、ホームディレクトリにある設定ファイル（例：`~/.zshrc`）を直接編集してしまった場合、その変更は`chezmoi`の管理下にありません。

その変更を`chezmoi`の管理に取り込むには、`add`コマンドを使います。

```bash
# ~/.zshrc に加えた変更をchezmoiに取り込む
chezmoi add ~/.zshrc
```