<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@page import="java.net.InetAddress" %>
<%@page import="org.json.simple.JSONObject" %>
<%@page import="java.util.*" %>

<%@ page import="org.bitcoinj.script.*"%>
<%@ page import="org.bitcoinj.core.ECKey"%>
<%@ page import="org.bitcoinj.core.TransactionOutput"%>
<%@ page import="org.bitcoinj.core.TransactionInput"%>
<%@ page import="org.bitcoinj.core.Transaction"%>
<%@ page import="org.bitcoinj.core.Base58"%>
<%@ page import="org.bitcoinj.core.Sha256Hash"%>
<%@ page import="org.bitcoinj.core.Address"%>
<%@ page import="org.bitcoinj.core.Coin"%>
<%@ page import="org.bitcoinj.core.NetworkParameters"%>
<%@ page import="org.bitcoinj.wallet.Wallet"%>
<%@ page import="org.bitcoinj.core.Sha256Hash"%>
<%@ page import="org.bitcoinj.core.ECKey.ECDSASignature"%>
<%@ page import="org.bitcoinj.crypto.TransactionSignature"%>
<%@ page import="org.bitcoinj.script.Script"%>
<%@ page import="java.math.BigInteger"%>

<%@include file="00_constants.jsp"%>
<%@include file="00_utility.jsp"%>

<%
/***************輸入範例********************************************************
http://127.0.0.1:8088/wallet/aGetWalletList.jsp?appid=2019070311452584&cardid=1234567890123456
*******************************************************************************/

/***************輸出範例********************************************************
{"resultText":"Success","records":[{"Wallet_Name":"first wallet","Wallet_Id":"1"}],"resultCode":"00000"}
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

/*********************開始做事吧*********************/
String appId		= nullToString(request.getParameter("appId"), "");
String cardId		= nullToString(request.getParameter("cardId"), "");
String walletId		= nullToString(request.getParameter("walletId"), "");
String walletName	= nullToString(request.getParameter("walletName"), "");
String currencyId	= nullToString(request.getParameter("currencyId"), "");
String txHash		= nullToString(request.getParameter("txHash"), "");
String toAddress	= nullToString(request.getParameter("toAddress"), "");
String amount		= nullToString(request.getParameter("amount"), "");
String transactionFee		= nullToString(request.getParameter("transactionFee"), "");

if (beEmpty(appId) || appId.length()!=16 || beEmpty(cardId) || cardId.length()!=16 ||  beEmpty(walletId) || beEmpty(currencyId) || beEmpty(txHash) || beEmpty(toAddress) || beEmpty(amount)){
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
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

String		address				= "";
String		publicKey			= "";
String		hashToBeSigned		= "";
String		transactionId		= generateRequestId();

String		sApdu				= "";
int			iSignatureCount		= 0;
String		aHash[]				= null;

//確認呼叫者身分
sSQL = "SELECT App_Id";
sSQL += " FROM cwallet_app_pair";
sSQL += " WHERE App_Id='" + appId + "' AND Card_Id='" + cardId + "' AND Status='Paired'";
ht = getDBData(sSQL, gcDataSourceNameCMSIOT);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();
if (!sResultCode.equals(gcResultCodeSuccess)){	//有誤
	obj.put("resultCode", gcResultCodeParametersValidationError);
	obj.put("resultText", gcResultTextParametersValidationError);
	out.print(obj);
	out.flush();
	return;
}


//取得Currency資訊
sSQL = "SELECT A.Publicy_Key, A.Address, B.Currency_Name";
sSQL += " FROM cwallet_wallet_currency A, cwallet_currency B";
sSQL += " WHERE A.Currency_Id = B.Currency_Id";
sSQL += " AND A.Card_Id='" + cardId + "'";
sSQL += " AND A.Wallet_Id='" + walletId + "'";
sSQL += " AND A.Currency_Id='" + currencyId + "'";
sSQL += " AND A.Status='Active'";
//writeLog("debug", sSQL);

ht = getDBData(sSQL, gcDataSourceNameCMSIOT);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s = (String[][])ht.get("Data");
	publicKey = s[0][0];
	address = s[0][1];
}else{
	obj.put("resultCode", sResultCode);
	obj.put("resultText", sResultText);
	out.print(obj);
	out.flush();
	return;
}

String unsignedHash = txHash;

NetworkParameters params = null;
if (currencyId.equals("BTC")) params = NetworkParameters.fromID(NetworkParameters.ID_MAINNET);
else params = NetworkParameters.fromID(NetworkParameters.ID_TESTNET);

Address myAddress = Address.fromString(params, address);

Transaction tx = new Transaction(params, hex2Byte(unsignedHash));

List  l1 = new LinkedList();
Map m1 = null;

for (i = 0; i < tx.getInputs().size(); i++) {
	TransactionInput transactionInput = tx.getInput(i);
	Script scriptPubKey = ScriptBuilder.createOutputScript(Address.fromString(params, address));
	
	Sha256Hash hash = tx.hashForSignature(i, scriptPubKey, Transaction.SigHash.ALL, true);
	hashToBeSigned += (beEmpty(hashToBeSigned)?byte2Hex(hash.getBytes()):"," + byte2Hex(hash.getBytes()));
	m1 = new HashMap();
	m1.put("hash", byte2Hex(hash.getBytes()));
	l1.add(m1);
	iSignatureCount++;
}

//在STK顯示給用戶看的訊息
ss = "Do you want to send  " + currencyId + " " + amount + " to " + toAddress + " ?";
ss = string2Hex(ss, "UTF8");
//sApdu = "AABBDD310000010101" + MakesUpZero(Integer.toHexString(ss.length()/2+3), 2) + "50" + MakesUpZero(walletId, 2) + MakesUpZero(Integer.toHexString(ss.length()/2), 2) + ss;
//UTF-8 傳 04 UCS2 傳08
sApdu = "AABBDD315000010101" + MakesUpZero(Integer.toHexString(ss.length()/2+2), 2) + MakesUpZero(walletId, 2) + "04" + ss;

sSQL = "INSERT INTO cwallet_bip_job_queue (Create_User, Create_Date, Update_User, Update_Date, Job_Id, Job_Description, Job_Type, App_Id, Card_Id, Transaction_Id, Wallet_Id, Wallet_Name, Currency_Id, CMD, APDU, Status) VALUES (";
sSQL += "'" + sUser + "',";
sSQL += "'" + sDate + "',";
sSQL += "'" + sUser + "',";
sSQL += "'" + sDate + "',";
sSQL += "'" + transactionId + "',";
sSQL += "'" + "Send " + currencyId + " " + amount + " to " + toAddress + "',";
sSQL += "'" + "T" + "',";
sSQL += "'" + appId + "',";
sSQL += "'" + cardId + "',";
sSQL += "'" + transactionId + "',";
sSQL += "'" + walletId + "',";
sSQL += "'" + walletName + "',";
sSQL += "'" + currencyId + "',";
sSQL += "'" + "50" + "',";
sSQL += "'" + sApdu + "',";
sSQL += "'" + "Init" + "'";
sSQL += ")";
sSQLList.add(sSQL);

sSQL = "INSERT INTO cwallet_transaction (Create_User, Create_Date, Update_User, Update_Date, App_Id, Card_Id, Wallet_Id, Transaction_Id, Currency_Id, To_Address, Amount, Transaction_Fee, Unsigned_Hex, Hash_To_Be_Signed, Signed_Hex, Signature_Count, Status) VALUES (";
sSQL += "'" + sUser + "',";
sSQL += "'" + sDate + "',";
sSQL += "'" + sUser + "',";
sSQL += "'" + sDate + "',";
sSQL += "'" + appId + "',";
sSQL += "'" + cardId + "',";
sSQL += "'" + walletId + "',";
sSQL += "'" + transactionId + "',";
sSQL += "'" + currencyId + "',";
sSQL += "'" + toAddress + "',";
sSQL += amount + ",";
sSQL += (beEmpty(transactionFee)?"0.0":transactionFee) + ",";
sSQL += "'" + unsignedHash + "',";
sSQL += "'" + hashToBeSigned + "',";
sSQL += "'" + "" + "',";
sSQL += String.valueOf(iSignatureCount) + ",";
sSQL += "'" + "Init" + "'";
sSQL += ")";
sSQLList.add(sSQL);

aHash = hashToBeSigned.split(",");
for (i=0; i<iSignatureCount; i++){
	sSQL = "INSERT INTO cwallet_transaction_hash (Create_User, Create_Date, Update_User, Update_Date, Transaction_Id, Hash_Index, Hash_To_Be_Signed, Signed_Hex, Status) VALUES (";
	sSQL += "'" + sUser + "',";
	sSQL += "'" + sDate + "',";
	sSQL += "'" + sUser + "',";
	sSQL += "'" + sDate + "',";
	sSQL += "'" + transactionId + "',";
	sSQL += String.valueOf(i+1) + ",";
	sSQL += "'" + aHash[i] + "',";
	sSQL += "NULL,";
	sSQL += "'" + "Init" + "'";
	sSQL += ")";
	sSQLList.add(sSQL);
}

ht = updateDBData(sSQLList, gcDataSourceNameCMSIOT, false);
sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

if (sResultCode.equals(gcResultCodeSuccess)){
	obj.put("records", l1);
}

obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);

out.print(obj);
out.flush();

//writeLog("debug", obj.toString());
%>
