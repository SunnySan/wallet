<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@page import="java.net.InetAddress" %>
<%@page import="org.json.simple.JSONObject" %>
<%@page import="java.util.*" %>

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

if (beEmpty(cardId)){
	writeLog("debug", "BIP get data to be signed parameter not found for Card_Id= " + cardId);
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
	return;
}else{
	writeLog("debug", "BIP get data to be signed for Card_Id= " + cardId);
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

String	walletId				= "";
String	path					= "";
String	currencyId				= "";
String	hashToBeSigned			= "";
String	sApdu					= "";

sSQL = "SELECT B.Wallet_Id, B.Currency_Id, B.Hash_To_Be_Signed";
sSQL += " FROM cwallet_bip_job_queue A, cwallet_transaction B";
sSQL += " WHERE A.Card_Id='" + cardId + "'";
sSQL += " AND A.CMD='" + "50" + "'";
sSQL += " AND A.Status='" + "Sync" + "'";
sSQL += " AND A.Transaction_Id=B.Transaction_Id";
sSQL += " ORDER BY A.id desc";
sSQL += " LIMIT 1";

ht = getDBData(sSQL, gcDataSourceNameCMSIOT);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s = (String[][])ht.get("Data");
	walletId = s[0][0];
	currencyId = s[0][1];
	hashToBeSigned = s[0][2];
	sApdu = "00";	//default = BTC
	if (currencyId.equals("BTCTEST")) sApdu = "01";
	if (currencyId.equals("ETH") || currencyId.equals("ETHTEST")) sApdu = "3C";
	sApdu = "8000002C" + "800000" + sApdu + "80000000" + "00000000" + "00000000";	//Path
	sApdu = "AABBDD510000010101" + MakesUpZero(Integer.toHexString((sApdu+hashToBeSigned).length()/2+1), 2) + MakesUpZero(walletId, 2) + sApdu + hashToBeSigned;
	obj.put("apdu", sApdu);
}else{
	writeLog("error", "BIP get hash to be signed failed, sResultCode= " + sResultCode + ", sResultText= " + sResultText);
	obj.put("resultCode", sResultCode);
	obj.put("resultText", sResultText);
	out.print(obj);
	out.flush();
	return;
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料


obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
writeLog("debug", "Response message= " + obj.toString());
out.print(obj);
out.flush();
%>
