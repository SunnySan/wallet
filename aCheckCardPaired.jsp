<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@page import="java.net.InetAddress" %>
<%@page import="org.json.simple.JSONObject" %>
<%@page import="java.util.*" %>

<%@include file="00_constants.jsp"%>
<%@include file="00_utility.jsp"%>

<%
/***************輸入範例********************************************************
http://127.0.0.1:8080/CHT/ajaxGetPaymentOrderList.jsp
*******************************************************************************/

/***************輸出範例********************************************************
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

if (beEmpty(appId) || appId.length()!=16){
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

sSQL = "SELECT Card_Id";
sSQL += " FROM cwallet_app_pair";
sSQL += " WHERE App_Id='" + appId + "' AND Status='Paired'";

ht = getDBData(sSQL, gcDataSourceNameCMSIOT);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s = (String[][])ht.get("Data");
	if (notEmpty(s[0][0])){
		obj.put("cardId", s[0][0]);
	}else{
		sResultCode = gcResultCodeNoDataFound;
		sResultText = gcResultTextNoDataFound;
	}
}

obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);

out.print(obj);
out.flush();

//writeLog("debug", obj.toString());
%>
