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

String	sResponse	= "";
/*********************開始做事吧*********************/
//String	sUrl = "https://www.blocktempo.com/category/latest-news/feed/";
String	sUrl = "https://cointelegraph.com/feed";
sUrl = "https://cointelegraph.com/feed";

	try{
		URL u;
		u = new URL(sUrl);
		HttpURLConnection uc = (HttpURLConnection)u.openConnection();
		uc.setRequestProperty("charset", "utf-8");
		uc.setRequestMethod("GET");
		uc.setUseCaches(false);
		uc.setAllowUserInteraction(false);
		uc.setRequestProperty("User-Agent","Mozilla/5.0");
		uc.setDoInput(true);
	
		InputStream in = uc.getInputStream();
		BufferedReader r = new BufferedReader(new InputStreamReader(in));
		StringBuffer buf = new StringBuffer();
		String line;
		while ((line = r.readLine())!=null) {
			buf.append(line);
		}
		in.close();
		sResponse = buf.toString();	//取得Line回應值
		sResponse = new String(sResponse.getBytes("UTF-8"),"UTF-8");
	}catch (IOException e){ 
		writeLog("error", "Exception when get news feed: " + e.toString());
	}

out.println(sResponse);
%>
