<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@page import="java.net.InetAddress" %>
<%@page import="org.json.simple.JSONObject" %>
<%@page import="java.util.*" %>

<%@ page import="org.bitcoinj.script.*"%>
<%@ page import="org.bitcoinj.core.ECKey"%>
<%@ page import="org.bitcoinj.core.NetworkParameters"%>

<%@include file="00_constants.jsp"%>
<%@include file="00_utility.jsp"%>
<%@include file="00_security.jsp"%>

<%

/*******************************************************************************
從SIM卡送回來的針對 job queue 工作的回覆
*******************************************************************************/

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

out.clear();	//注意，一定要有out.clear();，要不然client端無法解析XML，會認為XML格式有問題

String	sResponse	= "";
OutputStream o		= null;
/*********************開始做事吧*********************/

String cardId		= nullToString(request.getParameter("cid"), "");
String jobId		= nullToString(request.getParameter("jid"), "");
String walletId		= nullToString(request.getParameter("wid"), "");	//Create user/delete user response
String publicKey	= nullToString(request.getParameter("pkey"), "");	//Get child key
String resultCode	= nullToString(request.getParameter("rc"), "");	//Result code: all

writeLog("debug", "BIP card response Card_Id= " + cardId + ", Job_Id=" + jobId + ", Wallet_Id=" + walletId + ", Public_Key=" + publicKey + ", resultCode=" + resultCode);

if (beEmpty(cardId) || beEmpty(jobId) || beEmpty(resultCode)){
	writeLog("debug", "BIP card response parameter not found for Card_Id= " + cardId + ", Job_Id=" + jobId + ", Result_Code=" + resultCode);
	sResponse = "DDDDDD";
	o = response.getOutputStream();
	o.write(hex2Byte(sResponse));
	o.close();
	return;
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

byte[]		p1					= null;
byte[]		p2					= null;

sSQL = "SELECT id, Job_Type, App_Id, Transaction_Id, Wallet_Id, Wallet_Name, Currency_Id, Status";
sSQL += " FROM cwallet_bip_job_queue";
sSQL += " WHERE Job_Id='" + jobId + "'";
sSQL += " AND Card_Id='" + cardId + "'";

ht = getDBData(sSQL, gcDataSourceNameCMSIOT);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s = (String[][])ht.get("Data");
}else{
	writeLog("debug", "BIP job response failed, sResultCode= " + sResultCode + ", sResultText= " + sResultText);
	sResponse = "DDDDDD" + string2Hex(sResponse, "UTF-8");
	o = response.getOutputStream();
	o.write(hex2Byte(sResponse));
	o.close();
	return;
}

if (resultCode.equals("0")){	//用戶取消作業
	sSQL = "UPDATE cwallet_bip_job_queue";
	sSQL += " SET Status='Canceled'";
	sSQL += " WHERE Job_Id='" + jobId + "'";
	sSQL += " AND Card_Id='" + cardId + "'";
	sSQLList.add(sSQL);

	ht = updateDBData(sSQLList, gcDataSourceNameCMSIOT, false);
	sResultCode = ht.get("ResultCode").toString();
	sResultText = ht.get("ResultText").toString();
	
	if (sResultCode.equals(gcResultCodeSuccess)){
		writeLog("debug", "BIP job canceled, Job_Id= " + jobId + ", Card_Id= " + cardId);
		sResponse = "DDDDDDFD";
	}else{	//有問題
		writeLog("debug", "BIP job cancel failed, Job_Id= " + jobId + ", Card_Id= " + cardId + ", sResultCode= " + sResultCode + ", sResultText= " + sResultText);
		sResponse = sResultText;
		j = sResponse.length();
		p2 = new byte[] { (byte)j };
		sResponse = "DDDDDD00" + "00" + byte2Hex(p2) + string2Hex(sResponse, "UTF-8");
	}
	o = response.getOutputStream();
	o.write(hex2Byte(sResponse));
	o.close();
	return;
}

if (s[0][1].equals("C")){	//Create user
	if (beEmpty(walletId)){
		writeLog("debug", "BIP card response parameter not found for Card_Id= " + cardId + ", Job_Id=" + jobId + ", Result_Code=" + resultCode);
		sResponse = "DDDDDD";
		o = response.getOutputStream();
		o.write(hex2Byte(sResponse));
		o.close();
		return;
	}
	sSQL = "DELETE FROM cwallet_card_wallet";
	sSQL += " WHERE Card_Id='" + cardId + "'";
	sSQL += " AND Wallet_Id='" + walletId + "'";
	sSQLList.add(sSQL);
	
	sSQL = "DELETE FROM cwallet_wallet_currency";
	sSQL += " WHERE Card_Id='" + cardId + "'";
	sSQL += " AND Wallet_Id='" + walletId + "'";
	sSQLList.add(sSQL);
	
	sSQL = "INSERT INTO cwallet_card_wallet (Create_User, Create_Date, Update_User, Update_Date, Card_Id, Wallet_Id, Wallet_Name, Status) VALUES (";
	sSQL += "'" + sUser + "',";
	sSQL += "'" + sDate + "',";
	sSQL += "'" + sUser + "',";
	sSQL += "'" + sDate + "',";
	sSQL += "'" + cardId + "',";
	sSQL += "'" + walletId + "',";
	sSQL += "'" + s[0][5] + "',";
	sSQL += "'" + "Active" + "'";
	sSQL += ")";
	sSQLList.add(sSQL);
}

if (s[0][1].equals("R")){	//Rename wallet
	sSQL = "UPDATE cwallet_card_wallet";
	sSQL += " SET Wallet_Name='" + s[0][5] + "'";
	sSQL += " WHERE Card_Id='" + cardId + "'";
	sSQL += " AND Wallet_Id='" + s[0][4] + "'";
	sSQLList.add(sSQL);
}

if (s[0][1].equals("D")){	//Delete wallet
	sSQL = "DELETE FROM cwallet_card_wallet";
	sSQL += " WHERE Card_Id='" + cardId + "'";
	sSQL += " AND Wallet_Id='" + s[0][4] + "'";
	sSQLList.add(sSQL);
	
	sSQL = "DELETE FROM cwallet_wallet_currency";
	sSQL += " WHERE Card_Id='" + cardId + "'";
	sSQL += " AND Wallet_Id='" + s[0][4] + "'";
	sSQLList.add(sSQL);
}

if (s[0][1].equals("A")){	//Add currency
	if (beEmpty(publicKey)){
		writeLog("debug", "BIP card response parameter not found for Card_Id= " + cardId + ", Job_Id=" + jobId + ", Result_Code=" + resultCode);
		sResponse = "DDDDDD";
		o = response.getOutputStream();
		o.write(hex2Byte(sResponse));
		o.close();
		return;
	}

	org.bitcoinj.core.LegacyAddress myBitcoinAddress = null;
	if (s[0][6].equals("BTC")){
		myBitcoinAddress = (org.bitcoinj.core.LegacyAddress) org.bitcoinj.core.Address.fromKey(org.bitcoinj.core.NetworkParameters.fromID(org.bitcoinj.core.NetworkParameters.ID_MAINNET), org.bitcoinj.core.ECKey.fromPublicOnly(hex2Byte(publicKey)), org.bitcoinj.script.Script.ScriptType.P2PKH);
	}else{
		myBitcoinAddress = (org.bitcoinj.core.LegacyAddress) org.bitcoinj.core.Address.fromKey(org.bitcoinj.core.NetworkParameters.fromID(org.bitcoinj.core.NetworkParameters.ID_TESTNET), org.bitcoinj.core.ECKey.fromPublicOnly(hex2Byte(publicKey)), org.bitcoinj.script.Script.ScriptType.P2PKH);
	}
	String	myBitcoinAddressBase58 = myBitcoinAddress.toBase58();

	
	sSQL = "DELETE FROM cwallet_wallet_currency";
	sSQL += " WHERE Card_Id='" + cardId + "'";
	sSQL += " AND Wallet_Id='" + s[0][4] + "'";
	sSQL += " AND Currency_Id='" + s[0][6] + "'";
	sSQLList.add(sSQL);
	
	sSQL = "INSERT INTO cwallet_wallet_currency (Create_User, Create_Date, Update_User, Update_Date, Card_Id, Wallet_Id, Currency_Id, Publicy_Key, Address, Status) VALUES (";
	sSQL += "'" + sUser + "',";
	sSQL += "'" + sDate + "',";
	sSQL += "'" + sUser + "',";
	sSQL += "'" + sDate + "',";
	sSQL += "'" + cardId + "',";
	sSQL += "'" + walletId + "',";
	sSQL += "'" + s[0][6] + "',";
	sSQL += "'" + publicKey + "',";
	sSQL += "'" + myBitcoinAddressBase58 + "',";
	sSQL += "'" + "Active" + "'";
	sSQL += ")";
	sSQLList.add(sSQL);
}

sSQL = "UPDATE cwallet_bip_job_queue";
sSQL += " SET Status='Success'";
sSQL += " WHERE id=" + s[0][0];
sSQLList.add(sSQL);

ht = updateDBData(sSQLList, gcDataSourceNameCMSIOT, false);
sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

if (sResultCode.equals(gcResultCodeSuccess)){
	writeLog("debug", "BIP job response successfully, Job_Id= " + jobId + ", Card_Id= " + cardId);
	sResponse = "DDDDDDFD";
}else{	//有問題
	writeLog("debug", "BIP card pairing failed, Job_Id= " + jobId + ", Card_Id= " + cardId + ", sResultCode= " + sResultCode + ", sResultText= " + sResultText);
	sResponse = sResultText;
	j = sResponse.length();
	p2 = new byte[] { (byte)j };
	sResponse = "DDDDDD00" + "00" + byte2Hex(p2) + string2Hex(sResponse, "UTF-8");
}

writeLog("debug", "Response message= " + sResponse);

o = response.getOutputStream();
o.write(hex2Byte(sResponse));
o.close();
%>