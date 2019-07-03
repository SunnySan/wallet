<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@page import="java.net.InetAddress" %>
<%@page import="org.json.simple.JSONObject" %>
<%@page import="java.util.*" %>

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
String appId		= nullToString(request.getParameter("appid"), "");
String cardId		= nullToString(request.getParameter("cardid"), "");

if (beEmpty(appId) || appId.length()!=16 || beEmpty(cardId) || cardId.length()!=16){
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


//取得Wallet (User)清單
sSQL = "SELECT Wallet_Id, Wallet_Name";
sSQL += " FROM cwallet_card_wallet";
sSQL += " WHERE Card_Id='" + cardId + "' AND Status='Active'";

ht = getDBData(sSQL, gcDataSourceNameCMSIOT);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

List  l1 = new LinkedList();
Map m1 = null;

String[] fields = {"Wallet_Id", "Wallet_Name"};

if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s = (String[][])ht.get("Data");
	for (i=0;i<s.length;i++){
		m1 = new HashMap();
		for (j=0;j<fields.length;j++){
			m1.put(fields[j], nullToString(s[i][j], ""));
		}
		l1.add(m1);
	}
}else{
	obj.put("resultCode", sResultCode);
	obj.put("resultText", sResultText);
	out.print(obj);
	out.flush();
	return;
}

obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
obj.put("records", l1);

out.print(obj);
out.flush();

//writeLog("debug", obj.toString());
%>
