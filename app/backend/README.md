# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...


Here’s the clean, no-nonsense answer.
Assume **you pushed your Rails project (minus secrets)** and teammates want to run it inside **their own WSL2 Ubuntu** environment.

Below is exactly what they need to do — nothing more.

---

# ✅ **Steps Teammates Follow to Recreate & Run the Project in WSL2**

## **1. Install WSL2 + Ubuntu (same as you)**

PowerShell (Admin):

```powershell
wsl --install
```

Restart pc

```bash
wsl -d Ubuntu
sudo apt update && sudo apt upgrade -y
```

---

# ✅ **2. Install the Required Build Tools**

Inside Ubuntu:

```bash
sudo apt install -y git curl build-essential libssl-dev libreadline-dev \
zlib1g-dev autoconf bison libyaml-dev libffi-dev libgdbm-dev libncurses5-dev
```

---

# ✅ **3. Install rbenv + ruby-build**

```bash
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
exec $SHELL
```

---

# ✅ **4. Install the Exact Ruby Version Your Project Uses**

They must install **the same Ruby version in your `.ruby-version`** (or Gemfile).

Example:

```bash
rbenv install 3.3.10
rbenv global 3.3.10
```

Verify:

```bash
ruby -v
```

---

# ✅ **5. Install Rails**

```bash
gem install rails
```

---

# ✅ **6. Clone Your Project**

Inside Ubuntu, **not** `/mnt/c`:

```bash
cd ~
mkdir projects
cd projects
git clone https://github.com/Svampis/CS673-group-4.git
cd CS673-group-4/app/backend
```

Open in VS Code:

```bash
code .
```

---

# ✅ **7. Install Gems**

```bash
bundle install
```

---

# ❗ 8. Recreate the Missing Credential Files

Because you did **not** commit `master.key`, everyone must generate their own unless you share one securely.

Inside project:

```bash
EDITOR="code --wait" rails credentials:edit
```

This generates:

```
config/credentials.yml.enc
config/master.key
```

**DO NOT commit the master key.**
---



# ✅ **9. Run the Rails Server**

```bash
rails server
```

App runs at:

```
http://localhost:3000
```

---

