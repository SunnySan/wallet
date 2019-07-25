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
String action		= nullToString(request.getParameter("action"), "");	//C=Create, R=Rename, D=Delete, I=Import, A=Add currency to wallet
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

String	walletId				= data.substring(0, 2);
String	walletName				= (data.length()<3?"":data.substring(2));
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

	if (action.equals("D")){	//Delete Wallet
		sSQL = "DELETE FROM cwallet_card_wallet";
		sSQL += " WHERE Card_Id='" + cardId + "'";
		sSQL += " AND Wallet_Id='" + walletId + "'";
		sSQLList.add(sSQL);
	}
	
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
	writeLog("debug", "BIP wallet manipulation failed, sResultCode= " + sResultCode + ", sResultText= " + sResultText);
	obj.put("resultCode", sResultCode);
	obj.put("resultText", sResultText);
	out.print(obj);
	out.flush();
	return;
}

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