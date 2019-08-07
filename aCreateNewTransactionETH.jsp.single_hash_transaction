<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@page import="java.net.InetAddress" %>
<%@page import="org.json.simple.JSONObject" %>
<%@page import="java.util.*" %>

<%@page import="org.web3j.protocol.Web3j" %>
<%@page import="org.web3j.protocol.core.JsonRpc2_0Web3j" %>
<%@page import="org.web3j.protocol.http.HttpService" %>
<%@page import="org.web3j.protocol.core.DefaultBlockParameterName" %>
<%@page import="org.web3j.protocol.core.methods.response.EthGetTransactionCount" %>

<%@page import="org.ethereum.core.Transaction" %>
<%@page import="org.ethereum.util.ByteUtil" %>
<%@page import="org.apache.commons.codec.binary.Hex" %>

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
String toAddress	= nullToString(request.getParameter("toAddress"), "");
String amount		= nullToString(request.getParameter("amount"), "");
String gasPrice		= nullToString(request.getParameter("gasPrice"), "");
String gasLimit		= nullToString(request.getParameter("gasLimit"), "");

if (beEmpty(appId) || appId.length()!=16 || beEmpty(cardId) || cardId.length()!=16 ||  beEmpty(walletId) || beEmpty(currencyId) || beEmpty(gasPrice)  || beEmpty(gasLimit) || beEmpty(toAddress) || beEmpty(amount)){
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

String unsignedHash = "";
String ethApiEndPoint = "";

//注意：ETH mainnet chainId = 1, ropsten testnet chainId = 3
Integer chainId = 3;
if (currencyId.equals("ETH")){
	ethApiEndPoint = "https://mainnet.infura.io/v3/1a2cc5dffd8b46699947c7a73d152380";	//mainnet testnet
	chainId = 1;
}else{
	ethApiEndPoint = "https://ropsten.infura.io/v3/1a2cc5dffd8b46699947c7a73d152380";	//ropsten testnet
	chainId = 3;
}

//取得 Web3j 服務
//Web3j web3j = Web3j.build(new HttpService(ethApiEndPoint));	//這個寫法只能用於 JAVA 1.8以上
Web3j web3j = new JsonRpc2_0Web3j(new HttpService(ethApiEndPoint));


//取得sender address的 nonce
EthGetTransactionCount ethGetTransactionCount = web3j.ethGetTransactionCount(
             (address.startsWith("0x")?address:"0x"+address), DefaultBlockParameterName.LATEST).sendAsync().get();
BigInteger nonce = ethGetTransactionCount.getTransactionCount();
writeLog("debug", "nonce=" + nonce);

double d = Double.parseDouble(amount);
d = d * Double.parseDouble("1000000000000000000");
String sAmount = String.valueOf(d);

//建立未被簽名的 Transaction 物件
Transaction tx = new Transaction(
        ByteUtil.bigIntegerToBytes(nonce),
        ByteUtil.longToBytesNoLeadZeroes(Long.parseLong(gasPrice, 10)),
        ByteUtil.longToBytesNoLeadZeroes(Long.parseLong(gasLimit, 10)),
        hex2Byte(toAddress.startsWith("0x")||toAddress.startsWith("0X")?toAddress.substring(2):toAddress),
        ByteUtil.bigIntegerToBytes(BigInteger.valueOf((long)d)),  // wei
        null,
        chainId);
byte[] messageHash = tx.getRawHash();	//須被簽名的 hash
unsignedHash = byte2Hex(messageHash);

//在STK顯示給用戶看的訊息
ss = "Do you want to send  " + currencyId + " " + amount + " to " + toAddress + " ?";
ss = string2Hex(ss, "UTF8");
sApdu = "AABBDD310000010101" + MakesUpZero(Integer.toHexString(ss.length()/2+3), 2) + "50" + MakesUpZero(walletId, 2) + MakesUpZero(Integer.toHexString(ss.length()/2), 2) + ss;

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

sSQL = "INSERT INTO cwallet_transaction (Create_User, Create_Date, Update_User, Update_Date, App_Id, Card_Id, Wallet_Id, Transaction_Id, Currency_Id, To_Address, Amount, Transaction_Fee, Unsigned_Hex, Hash_To_Be_Signed, Signed_Hex, Status) VALUES (";
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
sSQL += String.valueOf(Float.parseFloat(gasPrice)/1000000000) + ",";	//注意：存成 GWei
sSQL += "'" + unsignedHash + "',";
sSQL += "'" + unsignedHash + "',";
sSQL += "'" + "" + "',";
sSQL += "'" + "Init" + "'";
sSQL += ")";
sSQLList.add(sSQL);

ht = updateDBData(sSQLList, gcDataSourceNameCMSIOT, false);
sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

if (sResultCode.equals(gcResultCodeSuccess)){
	obj.put("records", unsignedHash);
}

obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);

out.print(obj);
out.flush();

//writeLog("debug", obj.toString());
%>
