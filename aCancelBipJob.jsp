﻿<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@page import="java.net.InetAddress" %>
<%@page import="org.json.simple.JSONObject" %>
<%@page import="java.util.*" %>

<%@include file="00_constants.jsp"%>
<%@include file="00_utility.jsp"%>

<%
/***************輸入範例********************************************************
http://127.0.0.1:8088/wallet/aCreateWallet.jsp?appid=2019070311452584&cardid=1234567890123456
*******************************************************************************/

/***************輸出範例********************************************************
所有資料
{"resultCode":"00000","orders":[{"Create_Date":"2015-01-19 23:08","Update_Date_CS":null,"Last_Name":"hung","Arrive_Date":null,"Update_Date_CHT":null,"PaymentStatus":"Pay Success","Nationality":"Antarctica","Subscriber_ID":"14082511441646962E96","Product_E_Name":"testCHTnameLengthabcdefghijklmno","Queen_MSISDN":"886921139327","SendEmail":"N","Email":"gffjh@ggkbv.com","Product_SC_Name":"中华001","Update_User_ID_CHT":null,"Gender":"Female","First_Name":"popyyyo","Payment_Order_ID":"TX1501192C3162E03BE67313","Update_User_ID_CS":null,"Product_ID":"CHT001","Product_TC_Name":"中華001","MSISDN":"886910543001","DownloadStatus":"Receipt"},{"Create_Date":"2015-01-19 23:03","Update_Date_CS":null,"Last_Name":"hung","Arrive_Date":null,"Update_Date_CHT":null,"PaymentStatus":"Pay Success","Nationality":"Antarctica","Subscriber_ID":"14082511441646962E96","Product_E_Name":"testCHTnameLengthabcdefghijklmno","Queen_MSISDN":"886921139327","SendEmail":"N","Email":"gffjh@ggkbv.com","Product_SC_Name":"中华001","Update_User_ID_CHT":null,"Gender":"Female","First_Name":"popyyyo","Payment_Order_ID":"TX15011901DA55595D5898AD","Update_User_ID_CS":null,"Product_ID":"CHT001","Product_TC_Name":"中華001","MSISDN":"886910543000","DownloadStatus":"Receipt"}],"resultText":"Success"}
單一資料
{"resultCode":"00000","orders":[{"Create_Date":"2015-01-19 23:03","Update_Date_CS":null,"Last_Name":"hung","Arrive_Date":null,"Update_Date_CHT":null,"PaymentStatus":"Pay Success","Nationality":"Antarctica","Subscriber_ID":"14082511441646962E96","Product_E_Name":"testCHTnameLengthabcdefghijklmno","Queen_MSISDN":"886921139327","SendEmail":"N","Email":"gffjh@ggkbv.com","Product_SC_Name":"中华001","Update_User_ID_CHT":null,"Gender":"Female","First_Name":"popyyyo","Payment_Order_ID":"TX15011901DA55595D5898AD","Update_User_ID_CS":null,"Product_ID":"CHT001","Product_TC_Name":"中華001","MSISDN":"886910543000","DownloadStatus":"Receipt"}],"resultText":"Success"}
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
String idList		= nullToString(request.getParameter("idList"), "");

writeLog("debug", "Do cancel BIP jobs, appId=" + appId + ", cardId=" + cardId + ", idList=" + idList);

if (beEmpty(appId) || appId.length()!=16 || beEmpty(cardId) || cardId.length()!=16 || beEmpty(idList)){
	writeLog("debug", "Return: " + gcResultCodeParametersNotEnough + ", " + gcResultTextParametersNotEnough);
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

String		jobDescription		= "";
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

sSQL = "UPDATE cwallet_bip_job_queue SET Status='Canceled'";
sSQL += " ,Update_User='" + sUser + "'";
sSQL += " ,Update_Date='" + sDate + "'";
sSQL += " WHERE id IN " + idList;
sSQLList.add(sSQL);

sSQL = "UPDATE cwallet_transaction SET Status='Canceled'";
sSQL += " ,Update_User='" + sUser + "'";
sSQL += " ,Update_Date='" + sDate + "'";
sSQL += "WHERE Transaction_Id IN (SELECT Transaction_Id FROM cwallet_bip_job_queue WHERE id IN " + idList + ")";
sSQLList.add(sSQL);

sSQL = "UPDATE cwallet_transaction_hash SET Status='Canceled'";
sSQL += " ,Update_User='" + sUser + "'";
sSQL += " ,Update_Date='" + sDate + "'";
sSQL += "WHERE Transaction_Id IN (SELECT Transaction_Id FROM cwallet_bip_job_queue WHERE id IN " + idList + ")";
sSQLList.add(sSQL);

ht = updateDBData(sSQLList, gcDataSourceNameCMSIOT, false);
sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);

out.print(obj);
out.flush();

//writeLog("debug", obj.toString());
%>
