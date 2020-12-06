# 概要
+ 動作環境
  + ruby 2.5.1
  + bundle 2.1.4
  + 他のバージョンでは未確認
+ 説明
  + heron の予測を基に年間カレンダを作成するシステム．
  + 現在できること
    + 予定の予測
    + Google カレンダへの登録
    + Google カレンダの取得
  + 今後やること
    + ユーザの修正を契機とした予測結果の自動修正
    + 予測に用いる予定ごとの周期の任意設定
  
# Setup
+ このリポジトリを clone する．
```
$ git clone git@github.com:nakazono0424/heron.git
```
+ Rプロンプトで次のパッケージのインストールする．
```
pkgs <- c("RSQLite", "docopt", "shiny", "stringr", "ggplot2", "scales")
install.packages(pkgs)
```
+ gem をインストールする．
```
$ gem install bundler
$ bundle install --path vendor/bundle
```
+ OAuth 認証を行う．
```
$ bundle exec ruby main.rb
```
  この際，Google Calendar API の credentials.json が必要になる．
  + [Google API console](https://console.developers.google.com)
  
  認証に成功すると，`Aouthorize Success!`と表示される．

# Usage
```
$ Rscript --vanilla --slave bin/heron forecast --rname=RECURRENCE_NAME --input=FILE --forecast_year=YEAR > output.txt
$ bundle exec ruby bin/main.rb post_heron CALENDAR_ID TITLE output.txt
```

# DB スキーマ
+ heron は入力として SQLite を用いる．このとき，テーブル構造は次のようにする．
## TABLE Recurrence
  + id: integer
  + name: text
## TABLE Event
  + id: text
  + summary: text
  + recurrence_id: integer
  + start_time: datetime
  + end_time: datetime