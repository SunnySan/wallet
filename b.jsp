<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@page import="java.net.InetAddress" %>
<%@page import="org.json.simple.JSONObject" %>
<%@page import="org.json.simple.parser.JSONParser" %>
<%@page import="org.json.simple.parser.ParseException" %>
<%@page import="org.json.simple.JSONArray" %>
<%@page import="org.apache.commons.io.IOUtils" %>
<%@page import="java.util.*" %>
<%@page import="java.nio.charset.StandardCharsets" %>

<%@include file="00_constants.jsp"%>
<%@include file="00_utility.jsp"%>

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

//String	sResponse	= "AABBDDA000000101010100";
String	sResponse	= "";

//Sunny: 注意，第一行是一般用的，第二行是 cms.gslssd.com 的 docker 用的
//String	myURL		= request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+request.getContextPath()+"/";	//目前程式所處的URL路徑，不含檔名
String	myURL		= "http://ip-172-31-31-149.ap-southeast-1.compute.internal:8080/wallet/";	//目前程式所處的URL路徑，不含檔名

if (request.getServerPort()==8088){	//Sunny notebook
	myURL = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+request.getContextPath()+"/";	//目前程式所處的URL路徑，不含檔名
}else{
	myURL = "http://ip-172-31-31-149.ap-southeast-1.compute.internal:8080/wallet/";	//目前程式所處的URL路徑，不含檔名
}

OutputStream o		= null;
/*********************開始做事吧*********************/

String requestString		= nullToString(request.getParameter("c"), "");

writeLog("debug", "\n\n================================================================================");
writeLog("debug", "BIP command= " + requestString);
requestString = requestString.replaceAll("/", "");
writeLog("debug", "BIP command (remove slash)= " + requestString);

if (beEmpty(requestString) || requestString.length()<18){
	writeLog("debug", "BIP cmd is invalid= " + requestString);
	sResponse = "Invalid parameter";
	sResponse = "AABBDDA20000010101" + Integer.toHexString(string2Hex(sResponse, "UTF8").length()+1) + "04" + string2Hex(sResponse, "UTF8");
	writeLog("debug", "APDU Response= " + sResponse);
	writeLog("debug", "================================================================================\n\n");
	o = response.getOutputStream();
	o.write(hex2Byte(sResponse));
	o.close();
	return;
}

String	sResultCode	= gcResultCodeSuccess;
String	sResultText	= gcResultTextSuccess;

String	cardId		= requestString.substring(0, 16);
String	cmd			= requestString.substring(16, 18);
String	content		= "";
String	sJsp		= "";
String	sData		= "";
java.lang.Boolean	bOK = false;
String	sApdu		= "";
String	currencyId	= "";

if (requestString.length()>18) content = requestString.substring(18);

if (cmd.equals("30")){	//Link APP, pair with web/APP
	writeLog("debug", "Do job [  Pair Card ]");
	sJsp = "bPairCard.jsp";
	sData = "cardId=" + cardId;
	sData += "&pairCode=" + content;
}	//if (cmd.equals("30")){	//Link APP, pair with web/APP

if (cmd.equals("31")){	//Sync System
	writeLog("debug", "Do job [ Sync System ]");
	sJsp = "bSyncSystem.jsp";
	sData = "cardId=" + cardId;
}	//if (cmd.equals("31")){	//Sync System

if (cmd.equals("32")){	//Upload Wallet
	writeLog("debug", "Do job [ Upload wallet ]");
	sJsp = "bWalletManipulation.jsp";
	sData = "cardId=" + cardId;
	sData += "&action=U";
	sData += "&data=" + content;
}	//if (cmd.equals("32")){	//Upload Wallet

if (cmd.equals("33")){	//Get child (從卡片傳回
	writeLog("debug", "Do job [ Add Child Key ]");
	sJsp = "bWalletManipulation.jsp";
	sData = "cardId=" + cardId;
	sData += "&action=A";
	sData += "&data=" + content;
}	//if (cmd.equals("33")){	//Get child (從卡片傳回

if (cmd.equals("50")){	//Sign – Get Data
	writeLog("debug", "Do job [ Get Hash For Signing ]");
	sJsp = "bGetHashToBeSigned.jsp";
	sData = "cardId=" + cardId;
	sData += "&hashIndex=0";
}	//if (cmd.equals("51")){	//Sign – Get Data

if (cmd.equals("51")){	//Sign - Signature
	writeLog("debug", "Do job [ Get Hash For Signing or Send Raw Transaction ]");
	currencyId = getCurrencyIdOfTransaction(cardId);
	if (notEmpty(currencyId)){
		if (currencyId.equals("BTC") || currencyId.equals("BTCTEST")){
			//sJsp = "bPushSignedTransactionBTC.jsp";
			sJsp = "bGetHashToBeSigned.jsp";
			sData = "cardId=" + cardId;
			sData += "&hashIndex=" + Integer.parseInt(content.substring(2, 4), 16);	//把HEX字串的值轉成10進位的int
			sData += "&signature=" + content.substring(4);
		}else{
			sJsp = "bPushSignedTransactionETH.jsp";
			sData = "cardId=" + cardId;
			sData += "&data=" + content.substring(4);
		}
	}
}	//if (cmd.equals("52")){	//Sign - Signature

if (cmd.equals("40")){	//Create Wallet
	writeLog("debug", "Do job [ Create wallet ]");
	sJsp = "bWalletManipulation.jsp";
	sData = "cardId=" + cardId;
	sData += "&action=C";
	sData += "&data=" + content;
}	//if (cmd.equals("40")){	//Create Wallet

if (cmd.equals("41")){	//Import Wallet
	writeLog("debug", "Do job [ Import wallet ]");
	sJsp = "bWalletManipulation.jsp";
	sData = "cardId=" + cardId;
	sData += "&action=I";
	sData += "&data=" + content;
}	//if (cmd.equals("41")){	//Import Wallet

if (cmd.equals("43")){	//Rename Wallet
	writeLog("debug", "Do job [ Rename wallet ]");
	sJsp = "bWalletManipulation.jsp";
	sData = "cardId=" + cardId;
	sData += "&action=R";
	sData += "&data=" + content;
}	//if (cmd.equals("43")){	//Rename Wallet

if (cmd.equals("45")){	//Delete Wallet
	writeLog("debug", "Do job [ Delete wallet ]");
	sJsp = "bWalletManipulation.jsp";
	sData = "cardId=" + cardId;
	sData += "&action=D";
	sData += "&data=" + content;
}	//if (cmd.equals("45")){	//Delete Wallet


if (notEmpty(sJsp)){	//執行相對應的作業
	writeLog("debug", "Connect to BIP handler: " + myURL + sJsp);
	writeLog("debug", "Post data: " + sData);
	try{
		URL u;
		u = new URL(myURL + sJsp);
		HttpURLConnection uc = (HttpURLConnection)u.openConnection();
		//uc.setRequestProperty ("Content-Type", "application/json");
		uc.setRequestProperty("charset", "utf-8");
		uc.setRequestMethod("POST");
		uc.setRequestProperty("Content-Type", "application/x-www-form-urlencoded"); 
		uc.setDoOutput(true);
		uc.setDoInput(true);
	
		byte[] postData = sData.getBytes("UTF-8");	//避免中文亂碼問題
		OutputStream os = uc.getOutputStream();
		os.write(postData);
		os.close();
	
		InputStream in = uc.getInputStream();
		BufferedReader r = new BufferedReader(new InputStreamReader(in));
		StringBuffer buf = new StringBuffer();
		String line;
		while ((line = r.readLine())!=null) {
			buf.append(line);
		}
		in.close();
		sResponse = buf.toString();	//取得Line回應值
		bOK = true;
	}catch (IOException e){ 
		//sResponse = e.toString();
		sResponse = "Exception when send message to BIP handler, please try again later.";
		writeLog("error", "Exception when send message to BIP handler: " + e.toString());
		sResponse = "AABBDDA20000010101" + Integer.toHexString(string2Hex(sResponse, "UTF8").length()) + "04" + string2Hex(sResponse, "UTF8");
		writeLog("error", "APDU Response(Error)= " + sResponse);
		writeLog("debug", "================================================================================\n\n");
		o = response.getOutputStream();
		o.write(hex2Byte(sResponse));
		o.close();
		return;
	}
}	//if (notEmpty(sJsp)){	//執行相對應的作業

if (bOK && notEmpty(sResponse)){	//有取得JSP的回應
	//解析JSON參數
	JSONParser parser = new JSONParser();
	Object objBody = parser.parse(sResponse);
	JSONObject jsonObjectBody = (JSONObject) objBody;
	sResultCode = (String) jsonObjectBody.get("resultCode");
	sResultText = (String) jsonObjectBody.get("resultText");
	sApdu = (String) jsonObjectBody.get("apdu");
	if (sResultCode.equals(gcResultCodeSuccess)){
		if (beEmpty(sApdu)) sResponse = "AABBDDA000000101010100";
		else sResponse = sApdu;
	}else{
		sResponse = "AABBDDA20000010101" + MakesUpZero(Integer.toHexString(string2Hex(sResultText, "UTF8").length()/2+1), 2) + "04" + string2Hex(sResultText, "UTF8");
	}
}else{
	sResultText = "Unknown error";
	sResponse = "AABBDDA20000010101" + MakesUpZero(Integer.toHexString(string2Hex(sResultText, "UTF8").length()/2+1), 2) + "04" + string2Hex(sResultText, "UTF8");
}	//if (notEmpty(sResponse)){	//有取得JSP的回應

writeLog("debug", "APDU Response message= " + sResponse);
writeLog("debug", "================================================================================\n\n");

o = response.getOutputStream();
o.write(hex2Byte(sResponse));
o.close();

%>

<%!
	public String getCurrencyIdOfTransaction(String cardId){
		Hashtable	ht					= new Hashtable();
		String		sResultCode			= gcResultCodeSuccess;
		String		sResultText			= gcResultTextSuccess;
		String		s[][]				= null;
		String		sSQL				= "";
		String		currencyId			= "";

		sSQL = "SELECT B.Currency_Id";
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
			currencyId = s[0][0];
		}
		return currencyId;
	}
%>