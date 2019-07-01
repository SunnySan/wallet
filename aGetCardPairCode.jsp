<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@page import="java.net.InetAddress" %>
<%@page import="org.json.simple.JSONObject" %>
<%@page import="java.util.*" %>

<%@include file="00_constants.jsp"%>
<%@include file="00_utility.jsp"%>

<%
/***************輸入範例********************************************************
所有資料
http://127.0.0.1:8080/CHT/ajaxGetPaymentOrderList.jsp

單一資料
http://127.0.0.1:8080/CHT/ajaxGetPaymentOrderList.jsp?Payment_Order_ID=TX15011901DA55595D5898AD
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

String		sCode				= "";	//產生6碼隨機數
String		sAppId				= "";
java.lang.Boolean	bOK		= false;

bOK = false;
for (i=0;i<100;i++){
	sCode = generateRandomNuber(6);
	bOK = checkCode(sCode);
	if (bOK) break;
}

if (!bOK){
	obj.put("resultCode", gcResultCodeNoDataFound);
	obj.put("resultText", gcResultTextNoDataFound);
	out.print(obj);
	out.flush();
	return;
}

bOK = false;
for (i=0;i<100;i++){
	sAppId = generateRequestId();
	bOK = checkAppId(sAppId);
	if (bOK) break;
}

if (!bOK){
	obj.put("resultCode", gcResultCodeNoDataFound);
	obj.put("resultText", gcResultTextNoDataFound);
	out.print(obj);
	out.flush();
	return;
}

sSQL = "INSERT INTO cwallet_app_pair(Create_User, Create_Date, Update_User, Update_Date, App_Id, Card_Id, Pair_Code, Status) VALUES (";
sSQL += "'" + sUser + "',";
sSQL += "'" + sDate + "',";
sSQL += "'" + sUser + "',";
sSQL += "'" + sDate + "',";
sSQL += "'" + sAppId + "',";
sSQL += "'" + "" + "',";
sSQL += "'" + sCode + "',";
sSQL += "'" + "Init" + "'";
sSQL += ")";
sSQLList.add(sSQL);

ht = updateDBData(sSQLList, gcDataSourceNameCMSIOT, false);
sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

if (sResultCode.equals(gcResultCodeSuccess)){
	obj.put("appId", sAppId);
	obj.put("pairCode", sCode);
}else{
	obj.put("appId", "");
	obj.put("pairCode", "");
}

obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);

out.print(obj);
out.flush();

//writeLog("debug", obj.toString());
%>

<%!
	public java.lang.Boolean checkCode(String sCode){
		Hashtable	ht					= new Hashtable();
		String		sResultCode			= gcResultCodeSuccess;
		String		sResultText			= gcResultTextSuccess;
		String		s[][]				= null;
		String		sSQL				= "";

		sSQL = "SELECT *";
		sSQL += " FROM cwallet_app_pair";
		sSQL += " WHERE Pair_Code='" + sCode + "' AND Status='Init'";
		
		ht = getDBData(sSQL, gcDataSourceNameCMSIOT);
		
		sResultCode = ht.get("ResultCode").toString();
		sResultText = ht.get("ResultText").toString();
		if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
			return false;
		}else if(sResultCode.equals(gcResultCodeNoDataFound)){
			return true;
		}else{
			return false;
		}
	}

	public java.lang.Boolean checkAppId(String sAppId){
		Hashtable	ht					= new Hashtable();
		String		sResultCode			= gcResultCodeSuccess;
		String		sResultText			= gcResultTextSuccess;
		String		s[][]				= null;
		String		sSQL				= "";

		sSQL = "SELECT *";
		sSQL += " FROM cwallet_app_pair";
		sSQL += " WHERE App_Id='" + sAppId + "'";
		
		ht = getDBData(sSQL, gcDataSourceNameCMSIOT);
		
		sResultCode = ht.get("ResultCode").toString();
		sResultText = ht.get("ResultText").toString();
		if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
			return false;
		}else if(sResultCode.equals(gcResultCodeNoDataFound)){
			return true;
		}else{
			return false;
		}
	}
%>