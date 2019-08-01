<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@page import="java.net.InetAddress" %>
<%@page import="org.json.simple.JSONObject" %>
<%@page import="org.json.simple.parser.JSONParser" %>
<%@page import="org.json.simple.parser.ParseException" %>
<%@page import="org.json.simple.JSONArray" %>
<%@page import="org.apache.commons.io.IOUtils" %>
<%@page import="java.util.*" %>

<%@page import="org.web3j.protocol.Web3j" %>
<%@page import="org.web3j.protocol.http.HttpService" %>
<%@page import="org.web3j.protocol.core.DefaultBlockParameterName" %>

<%@page import="org.web3j.protocol.core.methods.response.EthGetTransactionCount" %>
<%@page import="org.web3j.protocol.core.methods.response.EthSendTransaction" %>



<%@page import="org.web3j.crypto.TransactionEncoder" %>
<%@page import="org.web3j.crypto.RawTransaction" %>

<%@ page import="java.math.BigInteger"%>

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
String senderAddress = "0xEF6046938e7F8508E934d53502957a755EB90315";
Web3j web3j = Web3j.build(new HttpService("https://morden.infura.io/3WPHYZR4JBK7C37Z5UEE821SJR3KRSYSP1"));
EthGetTransactionCount ethGetTransactionCount = web3j.ethGetTransactionCount(
             senderAddress, DefaultBlockParameterName.LATEST).sendAsync().get();

BigInteger nonce = ethGetTransactionCount.getTransactionCount();
BigInteger gasPrice = BigInteger.valueOf(20);	//Gwei
BigInteger gasLimit = BigInteger.valueOf(21000);
String to = "0x65D28726cFA311F80e2C02608185C9900861aad7";
BigInteger value = BigInteger.valueOf(1);

RawTransaction rawTransaction  = RawTransaction.createEtherTransaction(nonce, gasPrice, gasLimit, to, value);
%>