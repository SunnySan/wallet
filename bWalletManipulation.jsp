<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@page import="java.net.InetAddress" %>
<%@page import="org.json.simple.JSONObject" %>
<%@page import="java.util.*" %>

<%@ page import="org.bitcoinj.script.*"%>
<%@ page import="org.bitcoinj.core.ECKey"%>
<%@ page import="org.bitcoinj.core.NetworkParameters"%>

<%@ page import="org.web3j.crypto.Keys"%>
<%@ page import="org.web3j.crypto.ECKeyPair"%>
<%@ page import="org.spongycastle.jce.spec.*"%>

<%@include file="00_constants.jsp"%>
<%@include file="00_utility.jsp"%>

<%
/***************輸入範例********************************************************
https://cms.gslssd.com/wallet/bPair.jsp?cardid=1234567890123456&paircode=520333
*******************************************************************************/

/***************輸出範例********************************************************
成功
DDDDDDFD

失敗
DDDDDD0000596a6176612e73716c2e4261746368557064617465457863657074696f6e3a2044617461207472756e636174696f6e3a204461746120746f6f206c6f6e6720666f7220636f6c756d6e202749434349442720617420726f772031
*******************************************************************************/
%>

<%
request.setCharacterEncoding("utf-8");
response.setContentType("text/html;charset=utf-8");
response.setHeader("Pragma","no-cache"); 
response.setHeader("Cache-Control","no-cache"); 
response.setDateHeader("Expires", 0); 

out.clear();	//注意，一定要有out.clear();，要不然client端無法解析XML，會認為XML格式有問題

JSONObject	obj=new JSONObject();

String	sResponse	= "";

/*********************開始做事吧*********************/

String cardId		= nullToString(request.getParameter("cardId"), "");
String action		= nullToString(request.getParameter("action"), "");	//C=Create, R=Rename, D=Delete, I=Import, U=Upload wallet, A=Add currency to wallet
String data			= nullToString(request.getParameter("data"), "");

if (beEmpty(cardId) || beEmpty(action) || beEmpty(data) || data.length()<2){
	writeLog("debug", "BIP wallet manipulation parameter not found for Card_Id= " + cardId + ", action=" + action + ", data=" + data);
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
	return;
}else{
	writeLog("debug", "BIP wallet manipulation for Card_Id= " + cardId + ", action=" + action + ", data=" + data);
}

Hashtable	ht					= new Hashtable();
String		sResultCode			= gcResultCodeSuccess;
String		sResultText			= gcResultTextSuccess;
String		s[][]				= null;
String		sSQL				= "";
List<String> sSQLList			= new ArrayList<String>();
String		sDate				= getDateTimeNow(gcDateFormatSlashYMDTime);
String		sUser				= "System";

String		ss					= "";
int			i					= 0;
int			j					= 0;
int			k					= 0;
int			l					= 0;

String	walletId				= data.substring(0, 2);
String	walletName				= (data.length()<3?"":data.substring(2));
String	path					= "";
String	publicyKey				= "";
String	currencyType			= "";
String	currencyId				= "";
String	address					= "";

if (beEmpty(walletId) || (!action.equals("D") && beEmpty(walletName))){
	writeLog("debug", "BIP wallet manipulation parameter not found for walletId= " + walletId + ", walletName=" + walletName + ", action=" + action);
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
	return;
}

sSQL = "SELECT id";
sSQL += " FROM cwallet_card_wallet";
sSQL += " WHERE Card_Id='" + cardId + "'";
sSQL += " AND Wallet_Id='" + walletId + "'";

ht = getDBData(sSQL, gcDataSourceNameCMSIOT);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s = (String[][])ht.get("Data");
	ss = s[0][0];
	if (action.equals("C") || action.equals("I") || action.equals("R")){	//Create, Import, Rename Wallet
		sSQL = "UPDATE cwallet_card_wallet";
		sSQL += " SET Wallet_Name='" + walletName + "'";
		sSQL += " ,Update_User='" + sUser + "'";
		sSQL += " ,Update_Date='" + sDate + "'";
		sSQL += " ,Status='" + "Active" + "'";
		sSQL += " WHERE id=" + ss;
		sSQLList.add(sSQL);
	}

	if (action.equals("D") || action.equals("U")){	//D=Delete Wallet, U=Upload wallet
		sSQL = "DELETE FROM cwallet_card_wallet";
		sSQL += " WHERE Card_Id='" + cardId + "'";
		sSQL += " AND Wallet_Id='" + walletId + "'";
		sSQLList.add(sSQL);
		sSQL = "DELETE FROM cwallet_wallet_currency";
		sSQL += " WHERE Card_Id='" + cardId + "'";
		sSQL += " AND Wallet_Id='" + walletId + "'";
		sSQLList.add(sSQL);
	}

	if (action.equals("A")){	//A=Add currency to wallet
		currencyId = "ETH";
		sSQL = "SELECT Wallet_Id, Currency_Id";
		sSQL += " FROM cwallet_bip_job_queue";
		sSQL += " WHERE Card_Id='" + cardId + "'";
		sSQL += " AND CMD='33'";
		sSQL += " ORDER BY id desc";
		sSQL += " LIMIT 1";
		
		ht = getDBData(sSQL, gcDataSourceNameCMSIOT);
		
		sResultCode = ht.get("ResultCode").toString();
		sResultText = ht.get("ResultText").toString();
		if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
			s = (String[][])ht.get("Data");
			currencyId = s[0][1];
		}else{
			writeLog("debug", "BIP get child job not found for Card_Id= " + cardId + ", action=" + action + ", data=" + data);
			obj.put("resultCode", gcResultCodeNoDataFound);
			obj.put("resultText", gcResultTextNoDataFound);
			out.print(obj);
			out.flush();
			return;
		}
		/*
		path = data.substring(2, 42);
		currencyType = path.substring(14, 16);
		publicyKey = data.substring(42);
		*/
		publicyKey = data.substring(2);
		/*
		if (currencyType.equals("00")){
			currencyId = "BTC";
			address = getBitcoinAddressFromPublicKey(currencyId, publicyKey);
		}
		if (currencyType.equals("01")){
			currencyId = "BTCTEST";
			address = getBitcoinAddressFromPublicKey(currencyId, publicyKey);
		}
		*/
		if (currencyId.equals("BTC")){
			address = getBitcoinAddressFromPublicKey(currencyId, publicyKey);
		}
		if (currencyId.equals("BTCTEST")){
			address = getBitcoinAddressFromPublicKey(currencyId, publicyKey);
		}
		if (currencyId.equals("ETH") || currencyId.equals("ETHTEST")){
			//將 SIM 卡算出的 compressed public key 解壓縮，得到未被 compress 的 public key
			org.bitcoinj.core.ECKey pubKey = org.bitcoinj.core.ECKey.fromPublicOnly(hex2Byte(publicyKey));
			org.bitcoinj.core.ECKey decompressedPubKey = pubKey.decompress();
			byte[] baDecompressedPubKey = decompressedPubKey.getPubKey();
			writeLog("debug", "baDecompressedPubKey= " + byte2Hex(baDecompressedPubKey));
			
			//從未被 compress 的 public key 算出以太鏈的 address
			byte[] baAddress = org.ethereum.crypto.ECKey.computeAddress(baDecompressedPubKey);
			address = byte2Hex(baAddress);
		}
		//writeLog("debug", "path= " + path);
		//writeLog("debug", "currencyType= " + currencyType);
		writeLog("debug", "currencyId= " + currencyId);
		writeLog("debug", "publicyKey= " + publicyKey);
		writeLog("debug", "address= " + address);
		sSQL = "DELETE FROM cwallet_wallet_currency";
		sSQL += " WHERE Card_Id='" + cardId + "'";
		sSQL += " AND Wallet_Id='" + walletId + "'";
		sSQL += " AND Currency_Id='" + currencyId + "'";
		sSQLList.add(sSQL);
		sSQL = "INSERT INTO cwallet_wallet_currency (Create_User, Create_Date, Update_User, Update_Date, Card_Id, Wallet_Id, Currency_Id, Publicy_Key, Address, Status) VALUES (";
		sSQL += "'" + sUser + "',";
		sSQL += "'" + sDate + "',";
		sSQL += "'" + sUser + "',";
		sSQL += "'" + sDate + "',";
		sSQL += "'" + cardId + "',";
		sSQL += "'" + walletId + "',";
		sSQL += "'" + currencyId + "',";
		sSQL += "'" + publicyKey + "',";
		sSQL += "'" + address + "',";
		sSQL += "'" + "Active" + "'";
		sSQL += ")";
		sSQLList.add(sSQL);
	}	//if (action.equals("A")){	//A=Add currency to wallet
	
}else if (sResultCode.equals(gcResultCodeNoDataFound)){	//沒資料
	if (action.equals("C") || action.equals("I") || action.equals("R")){	//Create, Import, Rename Wallet
		sSQL = "INSERT INTO cwallet_card_wallet (Create_User, Create_Date, Update_User, Update_Date, Card_Id, Wallet_Id, Wallet_Name, Status) VALUES (";
		sSQL += "'" + sUser + "',";
		sSQL += "'" + sDate + "',";
		sSQL += "'" + sUser + "',";
		sSQL += "'" + sDate + "',";
		sSQL += "'" + cardId + "',";
		sSQL += "'" + walletId + "',";
		sSQL += "'" + walletName + "',";
		sSQL += "'" + "Active" + "'";
		sSQL += ")";
		sSQLList.add(sSQL);
	}

	if (action.equals("D")){	//Delete Wallet
		sResultCode = gcResultCodeSuccess;
		sResultText = gcResultTextSuccess;
	}
}else{
	writeLog("error", "BIP wallet manipulation failed, sResultCode= " + sResultCode + ", sResultText= " + sResultText);
	obj.put("resultCode", sResultCode);
	obj.put("resultText", sResultText);
	out.print(obj);
	out.flush();
	return;
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

if (action.equals("U")){	//Upload wallet，格式為 Card ID / 32 / ‘0’ ‘3’ / 01 08 “Jonathan” 02 03 “Ken” 03 07 “Charles”
	int walletCount = Integer.parseInt(data.substring(0, 2), 16);	//walletCount就是上面的‘0’ ‘3’
	writeLog("debug", "BIP upload wallet Card_Id= " + cardId + ", walletId= " + walletId + ", walletCount=" + String.valueOf(walletCount));
	if (walletCount>0){
		j = 0;
		k = 0;
		for (i=0;i<walletCount;i++){
			j = 2+k;	//walletId起始位置, 2是walletCount佔掉的 2 bytes
			walletId = data.substring(j, j+2);
			j=2+k+2;	//walletName長度起始位置
			l = Integer.parseInt(data.substring(j, j+2), 16);	//walletName長度
			walletName = data.substring(j+2, j+2+l);	//walletName
			k += 4+l;	//walletId 2 bytes, walletName長度 2bytes, walletName l bytes
			sSQL = "INSERT INTO cwallet_card_wallet (Create_User, Create_Date, Update_User, Update_Date, Card_Id, Wallet_Id, Wallet_Name, Status) VALUES (";
			sSQL += "'" + sUser + "',";
			sSQL += "'" + sDate + "',";
			sSQL += "'" + sUser + "',";
			sSQL += "'" + sDate + "',";
			sSQL += "'" + cardId + "',";
			sSQL += "'" + walletId + "',";
			sSQL += "'" + walletName + "',";
			sSQL += "'" + "Active" + "'";
			sSQL += ")";
			sSQLList.add(sSQL);
		}
	}	//if (walletCount>0){
}	//if (action.equals("U")){	//Upload wallet

if (sSQLList.size()<1 && !action.equals("D")){
	writeLog("debug", "BIP wallet manipulation (no SQL should be executed) parameter not found for Card_Id= " + cardId + ", action=" + action + ", data=" + data);
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
	return;
}

if (sSQLList.size()>0){
	ht = updateDBData(sSQLList, gcDataSourceNameCMSIOT, false);
	sResultCode = ht.get("ResultCode").toString();
	sResultText = ht.get("ResultText").toString();
	
	if (sResultCode.equals(gcResultCodeSuccess)){
		writeLog("debug", "BIP wallet manipulation successfully, Card_Id= " + cardId + ", Wallet_Id= " + walletId);
	}else{	//有問題
		writeLog("debug", "BIP wallet manipulation failed, sResultCode= " + sResultCode + ", sResultText= " + sResultText);
		obj.put("resultCode", sResultCode);
		obj.put("resultText", sResultText);
		out.print(obj);
		out.flush();
	}
}

obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
writeLog("debug", "Response message= " + obj.toString());
out.print(obj);
out.flush();
%>

<%!

public String getBitcoinAddressFromPublicKey(String currencyId, String sPublicKey){
	org.bitcoinj.core.LegacyAddress myBitcoinAddress = null;
	if (currencyId.equals("BTC")){
		myBitcoinAddress = (org.bitcoinj.core.LegacyAddress) org.bitcoinj.core.Address.fromKey(org.bitcoinj.core.NetworkParameters.fromID(org.bitcoinj.core.NetworkParameters.ID_MAINNET), org.bitcoinj.core.ECKey.fromPublicOnly(hex2Byte(sPublicKey)), org.bitcoinj.script.Script.ScriptType.P2PKH);
	}else{
		myBitcoinAddress = (org.bitcoinj.core.LegacyAddress) org.bitcoinj.core.Address.fromKey(org.bitcoinj.core.NetworkParameters.fromID(org.bitcoinj.core.NetworkParameters.ID_TESTNET), org.bitcoinj.core.ECKey.fromPublicOnly(hex2Byte(sPublicKey)), org.bitcoinj.script.Script.ScriptType.P2PKH);
	}
	String	myBitcoinAddressBase58 = myBitcoinAddress.toBase58();
	return myBitcoinAddressBase58;
}

%>