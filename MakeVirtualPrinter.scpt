(*
MakeVirtualPrinter.scpt
20160106初回作成
現時点では10.6.8のみ正常確認済

Acrobat9のppdをインストールして
PS書出し用のバーチャルルプリンタを各言語毎に追加します。

*)

-------設定ここから
--【設定項目】重要です良く読んでね
(*
セキュリティに関わります２を選ぶ場合は自己責任で
1：デフォルト値：spoolのアクセス権を操作しません。
2：マニア向け：CUPSのスプールディレクトリをアクセス可能にして
			ユーザーディレクトリにシンボリックリンクを作成します
			その後でログインユーザーをPrint Operatorグループに追加します
			
*)
---1か2を設定
set numSpoolPerm to 2 as number
-------設定ここまで



---System Eventsを起動しておく
tell application "System Events"
	launch
end tell
---ログを表示
tell application "AppleScript Editor"
	activate
	try
		tell application "System Events" to keystroke "3" using {command down}
	end try
	try
		tell application "System Events" to keystroke "l" using {option down, command down}
	end try
end tell
---ユーザー名を取得する
set objSysInfo to system info
set theUserName to (short user name of objSysInfo) as text
----これはついで
try
	do shell script "chflags nohidden  ~/Library"
end try
---日付けと時間からテンポラリー用のフォルダ名を作成
set theNowTime to (my doDateAndTIme(current date)) as text
---テンポラリー用フォルダのパスを定義
set theTrashDir to ("/tmp/" & theNowTime) as text
-----テンポラリーフォルダを作成
try
	set theCommand to ("mkdir -pv " & theTrashDir) as text
	do shell script theCommand
	set theTmpPath to theTrashDir as text
	delay 1
on error
	return "【エラー】テンポラリフォルダ作成でエラーが発生しました"
end try
-----ファイルをダウンロード
try
	set theCommand to ("curl -o '" & theTmpPath & "/ppdfiles.zip' 'http://force4u.cocolog-nifty.com/file/ppdfiles.zip'") as text
	do shell script theCommand
	delay 1
on error
	return "【エラー】ダウンロードでエラーが発生しました"
end try
-----ファイルを解凍
try
	set theCommand to ("unzip '" & theTmpPath & "/ppdfiles.zip' -d '" & theTmpPath & "'") as text
	do shell script theCommand
	delay 1
on error
	return "【エラー】ファイルの解凍でエラーが発生しました"
end try
-----インストール先のフォルダを確保
try
	set theCommand to ("sudo mkdir -p '/Library/Printers/PPDs/Contents/Resources/VirtualPrinter'") as text
	do shell script theCommand with administrator privileges
on error
	----ここはエラー制御無しで
end try
-----ファイルを移動（おきかえ）
try
	set theCommand to ("sudo mv -f " & theTmpPath & "/ppdfiles/* '/Library/Printers/PPDs/Contents/Resources/VirtualPrinter'") as text
	do shell script theCommand with administrator privileges
on error
	---ここはエラー制御無しでOKかな
end try
----アクセス権設定
try
	set theCommand to ("sudo chmod 777 '/Library/Printers/PPDs/Contents/Resources/VirtualPrinter'") as text
	do shell script theCommand with administrator privileges
	set theCommand to ("sudo chmod 666 /Library/Printers/PPDs/Contents/Resources/VirtualPrinter/*") as text
	do shell script theCommand with administrator privileges
	
on error
	---ここはエラー制御無しでOKかな
end try
----初期化
set thePrinterStat to "\r"
----プリンターリストを取得
set thePrinterStat to (do shell script "lpstat -p | awk '{print $2}'") as text
---改行コード整形
set thePrinterStat to doReplace(thePrinterStat, "\r\r", "\r") as text
-------１行づつ処理するために改行で区切りリストにする
set AppleScript's text item delimiters to {"\r"}
---プリントキュー毎にリストにする
set thePrinterStatlist to (every text item of thePrinterStat) as list
---プリンタの台数を確定
set numPrinter to count of thePrinterStatlist
---処理番号リセット
set numPrinterNo to 1 as number
---繰り返しの始まり
repeat numPrinter times
	----処理するキューを確定
	set thePrinterQue to (item numPrinterNo of thePrinterStatlist) as text
	---ここの２重トライは不要か？
	try
		try
			------キューを空にする
			if thePrinterQue is not "" then
				do shell script "lprm -P " & thePrinterQue & ""
			end if
		end try
	on error
		exit repeat
	end try
	---カウントアップ
	set numPrinterNo to (numPrinterNo + 1) as number
end repeat
------プリンターの削除
try
	do shell script "lpadmin -x VrPriAcro9EN"
	do shell script "lpadmin -x VrPriAcro9JP"
	do shell script "lpadmin -x VrPriAcro9CS"
	do shell script "lpadmin -x VrPriAcro9CT"
	do shell script "lpadmin -x VrPriAcro9KR"
	do shell script "lpadmin -x VrPriDsTrueflow"
end try
---プリンターアプリを削除
try
	set theUserPath to ("/Users/" & theUserName & "/Library/Printers/VrPriAcro9EN") as text
	do shell script "rm -Rf " & theUserPath & ""
	set theUserPath to ("/Users/" & theUserName & "/Library/Printers/VrPriAcro9JP") as text
	do shell script "rm -Rf " & theUserPath & ""
	set theUserPath to ("/Users/" & theUserName & "/Library/Printers/VrPriAcro9CS") as text
	do shell script "rm -Rf " & theUserPath & ""
	set theUserPath to ("/Users/" & theUserName & "/Library/Printers/VrPriAcro9CT") as text
	do shell script "rm -Rf " & theUserPath & ""
	set theUserPath to ("/Users/" & theUserName & "/Library/Printers/VrPriAcro9KR") as text
	do shell script "rm -Rf " & theUserPath & ""
	set theUserPath to ("/Users/" & theUserName & "/Library/Printers/VrPriDsTrueflow") as text
	do shell script "rm -Rf " & theUserPath & ""
end try
---ここからプリンタ登録
------------------------VrPriAcro9EN
try
	---プリンタを登録
	do shell script "lpadmin -p \"VrPriAcro9EN\" -E -v lpd://localhost/VrPriAcro9EN -P \"/Library/Printers/PPDs/Contents/Resources/VirtualPrinter/ADPDF9.PPD\" -D \"Acrobat9PpdPrinterEN\" -L \"Adobe PDF 9 Roman(バーチャル・プリンタ)\" -o printer-is-shared=false"
	---印刷は出来ないので停止させる
	do shell script "cupsdisable  \"VrPriAcro9EN\""
on error
	---エラーメッセージ
	set Mes to "【エラー】VrPriAcro9ENでエラーがになりました\nパスワードをご確認ください" as text
	return Mes
end try
------------------------VrPriAcro9JP
try
	---プリンタを登録
	do shell script "lpadmin -p \"VrPriAcro9JP\" -E -v lpd://localhost/VrPriAcro9JP -P \"/Library/Printers/PPDs/Contents/Resources/VirtualPrinter/ADPDF9J.PPD\" -D \"Acrobat9PpdPrinterJP\" -L \"Adobe PDF 9 Japanese(日本語バーチャル・プリンタ)\" -o printer-is-shared=false"
	---印刷は出来ないので停止させる
	do shell script "cupsdisable  \"VrPriAcro9JP\""
on error
	---エラーメッセージ
	set Mes to "【エラー】VrPriAcro9JPでエラーがになりました\nパスワードをご確認ください" as text
	return Mes
end try
------------------------VrPriAcro9CS
try
	---プリンタを登録
	do shell script "lpadmin -p \"VrPriAcro9CS\" -E -v lpd://localhost/VrPriAcro9CS -P \"/Library/Printers/PPDs/Contents/Resources/VirtualPrinter/ADPDF9CS.PPD\" -D \"Acrobat9PpdPrinterCS\" -L \"Adobe PDF 9 Simplified Chinese(簡体字・北京語バーチャル・プリンタ)\" -o printer-is-shared=false"
	---印刷は出来ないので停止させる
	do shell script "cupsdisable  \"VrPriAcro9CS\""
on error
	---エラーメッセージ
	set Mes to "【エラー】VrPriAcro9CSでエラーがになりました\nパスワードをご確認ください" as text
	return Mes
end try

------------------------VrPriAcro9CT
try
	---プリンタを登録
	do shell script "lpadmin -p \"VrPriAcro9CT\" -E -v lpd://localhost/VrPriAcro9CT -P \"/Library/Printers/PPDs/Contents/Resources/VirtualPrinter/ADPDF9CT.PPD\" -D \"Acrobat9PpdPrinterCT\" -L \"Adobe PDF 9 Traditional Chinese(繁体字・台湾語バーチャル・プリンタ)\" -o printer-is-shared=false"
	---印刷は出来ないので停止させる
	do shell script "cupsdisable  \"VrPriAcro9CT\""
on error
	---エラーメッセージ
	set Mes to "【エラー】VrPriAcro9CTでエラーがになりました\nパスワードをご確認ください" as text
	return Mes
end try
------------------------VrPriAcro9KR
try
	---プリンタを登録
	do shell script "lpadmin -p \"VrPriAcro9KR\" -E -v lpd://localhost/VrPriAcro9KR -P \"/Library/Printers/PPDs/Contents/Resources/VirtualPrinter/ADPDF9K.PPD\" -D \"Acrobat9PpdPrinterKR\" -L \"Adobe PDF 9 Korean(ハングル・韓国語バーチャル・プリンタ)\" -o printer-is-shared=false"
	---印刷は出来ないので停止させる
	do shell script "cupsdisable  \"VrPriAcro9KR\""
on error
	---エラーメッセージ
	set Mes to "【エラー】VrPriAcro9KRでエラーがになりました\nパスワードをご確認ください" as text
	return Mes
end try
------------------------VrPriDsTrueflow
try
	---プリンタを登録
	do shell script "lpadmin -p \"VrPriDsTrueflow\" -E -v lpd://localhost/VrPriDsTrueflow -P \"/Library/Printers/PPDs/Contents/Resources/VirtualPrinter/DS TRUEFLOW_J V1.4\" -D \"DsTrueflowPpdPrinter\" -L \"DS TRUEFLOW_J V1.4(バーチャル・プリンタ)\" -o printer-is-shared=false"
	---印刷は出来ないので停止させる
	do shell script "cupsdisable  \"VrPriDsTrueflow\""
on error
	---エラーメッセージ
	set Mes to "【エラー】VrPriDsTrueflowでエラーがになりました\nパスワードをご確認ください" as text
	return Mes
end try
-----WEBインターフェイスを有効にする
try
	do shell script "cupsctl WebInterface=yes"
end try
-----SPOOLディレクトリのアクセス権設定他マニア向き
if numSpoolPerm is 2 then
	----	ログインユーザーをPrint Operatorグループに追加する
	try
		set theCommand to ("sudo dseditgroup -o edit -a " & theUserName & " -t user '_lp'") as text
		do shell script theCommand with administrator privileges
		delay 0.5
	end try
	----	ログインユーザーをPrint Adminグループに追加する
	try
		set theCommand to ("sudo dseditgroup -o edit -a " & theUserName & " -t user '_lpadmin'") as text
		do shell script theCommand with administrator privileges
		delay 0.5
	end try
	----	ログインユーザーをPrint Adminグループに追加する
	try
		set theCommand to ("sudo dseditgroup -o edit -a " & theUserName & " -t user '_lpoperator'") as text
		do shell script theCommand with administrator privileges
		delay 0.5
	end try
	try
		set theCommand to ("ln -s '/private/var/spool/cups' '/Users/" & theUserName & "/CUPS'") as text
		do shell script theCommand with administrator privileges
	end try
	----	SPOOLディレクトリのアクセス権設定
	try
		do shell script "sudo chmod -f 777 '/private/var/spool'" with administrator privileges
		delay 0.5
	end try
	try
		do shell script "sudo chmod -f 777 '/private/var/spool/cups'" with administrator privileges
		delay 0.5
	end try
end if

----システム環境設定のプリンタを開く
tell application "Finder"
	activate
	try
		do shell script "open /System/Library/PreferencePanes/PrintAndScan.prefPane"
	on error
		try
			do shell script "open /System/Library/PreferencePanes/PrintAndFax.prefPane"
		end try
	end try
end tell
----CUPSのWEBインターフェイスを開く
set theUrl to "http://localhost:631/printers/" as text
set appName to "Safari"
tell application "Safari"
	activate
	make new document
	tell window 1
		open location theUrl
	end tell
end tell
---終了メッセージ
set Mes to "処理は終了しました。\n" as text
return Mes




--------------------------------------------------#ここからサブルーチン
to doDateAndTIme(theDate)
	set y to (year of theDate)
	set m to my monthNumStr(month of theDate)
	set d to day of theDate
	set hms to time of theDate
	set hh to h of sec2hms(hms)
	set mm to m of sec2hms(hms)
	set ss to s of sec2hms(hms)
	return (y as text) & my zero1(m) & my zero1(d) & "_" & zero1(hh) & zero1(mm) & zero1(ss)
	return (y as text) & my zero1(m) & my zero1(d)
end doDateAndTIme

------------------------------
to monthNumStr(theMonth)
	set monList to {January, February, March, April, May, June, July, August, September, October, November, December}
	repeat with i from 1 to 12
		if item i of monList is theMonth then exit repeat
	end repeat
	return i
end monthNumStr
------------------------------
to sec2hms(sec)
	set ret to {h:0, m:0, s:0}
	set h of ret to sec div hours
	set m of ret to (sec - (h of ret) * hours) div minutes
	set s of ret to sec mod minutes
	return ret
end sec2hms
------------------------------
to zero1(n)
	if n < 10 then
		return "0" & n
	else
		return n as text
	end if
end zero1
------------------------------文字の置き換えのサブルーチン
to doReplace(theText, orgStr, newstr)
	set oldDelim to AppleScript's text item delimiters
	set AppleScript's text item delimiters to orgStr
	set tmpList to every text item of theText
	set AppleScript's text item delimiters to newstr
	set tmpStr to tmpList as text
	set AppleScript's text item delimiters to oldDelim
	return tmpStr
end doReplace

