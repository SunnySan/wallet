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

out.clear();	//注意，一定要有out.clear();，要不然client端無法解析XML，會認為XML格式有問題

String	sResponse	= "";
OutputStream o		= null;
/*********************開始做事吧*********************/

String cardId		= nullToString(request.getParameter("cardId"), "");
String pairCode		= nullToString(request.getParameter("pairCode"), "");

if (beEmpty(cardId) || beEmpty(pairCode) || cardId.length()!=16 || pairCode.length()!=6){
	writeLog("debug", String.valueOf(cardId.length()) + "," + String.valueOf(pairCode.length()) + "BIP card pairing parameter not found for Card_Id= " + cardId + ", Pair_Code=" + pairCode);
	sResponse = "DDDDDD";
	o = response.getOutputStream();
	o.write(hex2Byte(sResponse));
	o.close();
	return;
}else{
	writeLog("debug", "BIP account registration for Card_Id= " + cardId + ", Pair_Code=" + pairCode);
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

sSQL = "SELECT id, App_Id";
sSQL += " FROM cwallet_app_pair";
sSQL += " WHERE Pair_Code='" + pairCode + "'";
sSQL += " AND DATE_ADD( Create_Date , INTERVAL 20 MINUTE )>'" + sDate + "'";
sSQL += " AND Status='Init'";

ht = getDBData(sSQL, gcDataSourceNameCMSIOT);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s = (String[][])ht.get("Data");
}else{
	writeLog("debug", "BIP card pairing failed, sResultCode= " + sResultCode + ", sResultText= " + sResultText);
	sResponse = "DDDDDD" + string2Hex(sResponse, "UTF-8");
	o = response.getOutputStream();
	o.write(hex2Byte(sResponse));
	o.close();
	return;
}

sSQL = " UPDATE cwallet_app_pair";
sSQL += " SET Status='Paired'";
sSQL += " , Card_Id='" + cardId + "'";
sSQL += " WHERE id=" + s[0][0];
sSQLList.add(sSQL);

ht = updateDBData(sSQLList, gcDataSourceNameCMSIOT, false);
sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

if (sResultCode.equals(gcResultCodeSuccess)){
	writeLog("debug", "BIP card pairing successfully, Card_Id= " + cardId + ", App_Id= " + s[0][1]);
	sResponse = "DDDDDDFD";
}else{	//有問題
	writeLog("debug", "BIP card pairing failed, sResultCode= " + sResultCode + ", sResultText= " + sResultText);
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