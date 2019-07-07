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
String coinType		= nullToString(request.getParameter("cointype"), "");
String txHex		= nullToString(request.getParameter("txhex"), "");

if (beEmpty(coinType) || beEmpty(txHex)){
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
URL			u;
String		sUrl				= "";
String		sData				= "";
String		sResponse			= "";

if (coinType.equals("BTC")){
	sUrl = "https://chain.so/api/v2/send_tx/BTC";
}else{
	sUrl = "https://chain.so/api/v2/send_tx/BTCTEST";
}
sData = "tx_hex=" + txHex;

try
{
	writeLog("debug", "Send transaction hex to " + sUrl + ", data= " + sData);

String urlParameters  = sData;
byte[] postData       = urlParameters.getBytes( StandardCharsets.UTF_8 );
int    postDataLength = postData.length;


	
	u = new URL(sUrl);
	HttpURLConnection uc = (HttpURLConnection)u.openConnection();
uc.setRequestProperty( "Content-Type", "application/x-www-form-urlencoded"); 
//uc.setRequestProperty( "charset", "utf-8");
uc.setRequestProperty( "Content-Length", Integer.toString( postDataLength ));
uc.setUseCaches( false );
	uc.setRequestMethod("POST");
	uc.setDoOutput(true);
	uc.setDoInput(true);


      uc.setRequestProperty("User-agent", "Mozilla/5.0 (Windows; U; Windows NT 6.0; zh-TW; rv:1.9.1.2) " + "Gecko/20090729 Firefox/3.5.2 GTB5 (.NET CLR 3.5.30729)"); 
      uc.setRequestProperty("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"); 
      uc.setRequestProperty("Accept-Language", "zh-tw,en-us;q=0.7,en;q=0.3"); 
      uc.setRequestProperty("Accept-Charse", "Big5,utf-8;q=0.7,*;q=0.7"); 
      //uc.setRequestProperty("Content-Length", sData.getBytes().length); 
      /*
      java.io.DataOutputStream dos = new java.io.DataOutputStream(uc 
          .getOutputStream()); 
      dos.writeBytes(sData); 
      */



try( DataOutputStream wr = new DataOutputStream( uc.getOutputStream())) {
   wr.write( postData );
}


/*	
	byte[] postData = sData.getBytes("UTF-8");	//避免中文亂碼問題
	OutputStream os = uc.getOutputStream();
	os.write(postData);
	os.close();
*/
	

	InputStream in = uc.getInputStream();
	BufferedReader r = new BufferedReader(new InputStreamReader(in));
	StringBuffer buf = new StringBuffer();
	String line;
	while ((line = r.readLine())!=null) {
		buf.append(line);
	}
	in.close();
	sResponse = buf.toString();	//取得回應值
	if (notEmpty(sResponse)){
		//解析JSON參數
		JSONParser parser = new JSONParser();
		Object objBody = parser.parse(sResponse);
		JSONObject jsonObjectBody = (JSONObject) objBody;
		ss = (String) jsonObjectBody.get("status");
		if (beEmpty(ss) || !ss.equals("success")){
			sResultCode = gcResultCodeUnknownError;
			sResultText = ss;
		}else{
			objBody = jsonObjectBody.get("data");
			jsonObjectBody = (JSONObject) objBody;
			obj.put("txid", (String) jsonObjectBody.get("txid"));
		}
	}else{
		sResultCode = gcResultCodeUnknownError;
		sResultText = gcResultTextUnknownError;
	}
}catch (IOException e){
	sResponse = e.toString();
	writeLog("error", "Exception when broadcast transaction to chain: " + e.toString());
	sResultCode = gcResultCodeUnknownError;
	//sResultText = sResponse;
	sResultText = "Unable to broadcast transaction to chain " + sResponse;
}


obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);

out.print(obj);
out.flush();

writeLog("debug", obj.toString());
%>
