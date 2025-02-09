﻿<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@page import="java.net.InetAddress" %>
<%@page import="org.json.simple.JSONObject" %>
<%@page import="org.json.simple.parser.JSONParser" %>
<%@page import="org.json.simple.parser.ParseException" %>
<%@page import="org.json.simple.JSONArray" %>
<%@page import="org.apache.commons.io.IOUtils" %>
<%@page import="java.util.*" %>

<%@ page import="org.bitcoinj.script.*"%>
<%@ page import="org.bitcoinj.core.ECKey"%>
<%@ page import="org.bitcoinj.core.NetworkParameters"%>
<%@ page import="java.math.BigInteger"%>
<%@ page import="org.web3j.crypto.Keys"%>
<%@ page import="org.web3j.crypto.ECKeyPair"%>

<%@ page import="org.spongycastle.jce.spec.*"%>

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

String sPublicKey			= nullToString(request.getParameter("PublicKey"), "");

sPublicKey = sPublicKey.replaceAll("0x", "");
sPublicKey = sPublicKey.replaceAll("0X", "");
writeLog("debug", "PublicKey= " + sPublicKey);

if (beEmpty(sPublicKey)){
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
	return;
}

String	sResponse	=	"";
/*
//org.bitcoinj.core.LegacyAddress myBitcoinAddress = (org.bitcoinj.core.LegacyAddress) org.bitcoinj.core.Address.fromKey(org.bitcoinj.core.NetworkParameters.fromID(org.bitcoinj.core.NetworkParameters.ID_MAINNET), org.bitcoinj.core.ECKey.fromPublicOnly(hex2Byte(sPublicKey)), org.bitcoinj.script.Script.ScriptType.P2PKH);
org.bitcoinj.core.LegacyAddress myBitcoinAddress = (org.bitcoinj.core.LegacyAddress) org.bitcoinj.core.Address.fromKey(org.bitcoinj.core.NetworkParameters.fromID(org.bitcoinj.core.NetworkParameters.ID_TESTNET), org.bitcoinj.core.ECKey.fromPublicOnly(hex2Byte(sPublicKey)), org.bitcoinj.script.Script.ScriptType.P2PKH);
//NetworkParameters.ID_TESTNET -> NetworkParameters.ID_MAINNET

String	myBitcoinAddressBase58 = myBitcoinAddress.toBase58();
sResponse = myBitcoinAddressBase58 + "<p>" + byte2Hex(myBitcoinAddress.getHash()) + "<p>" + byte2Hex(sha3(ECKey.fromPublicOnly(hex2Byte(sPublicKey)).decompress().getPubKey()));

String	myEthereumAddress = byte2Hex(org.ethereum.crypto.ECKey.fromPublicOnly(hex2Byte(sPublicKey)).getAddress());


Keccak.Digest256 digest256 = new Keccak.Digest256();
byte[] hashbytes = digest256.digest(
  ECKey.fromPublicOnly(hex2Byte(sPublicKey)).decompress().getPubKey());
String sha3_256hex = new String(byte2Hex(hashbytes));
sResponse += "<p>" + sha3_256hex;

sResponse += "<p>uncomressed public key= " + byte2Hex(ECKey.fromPublicOnly(hex2Byte(sPublicKey)).decompress().getPubKey());
*/

ECKey tempBitcoinKey = org.bitcoinj.core.ECKey.fromPublicOnly(hex2Byte(sPublicKey));
tempBitcoinKey = tempBitcoinKey.decompress();
byte[] bPublicKey = tempBitcoinKey.getPubKey();
out.print("<p>bPublicKey= " + byte2Hex(bPublicKey).substring(2));
String ss = byte2Hex(bPublicKey) + sPublicKey;
byte[] bs = hex2Byte(ss);
//ECKeyPair kp = Keys.deserialize(bs);
//out.print("<p>deserialize address= " + Keys.getAddress(kp));

byte[] bAddress = Keys.getAddress(bPublicKey);
String sAddress = byte2Hex(bAddress);
out.print("<p>sAddress= " + sAddress);
out.print("<p>sAddress= " + Keys.getAddress(byte2Hex(bPublicKey)));

out.print("<p>getAddress= " + Keys.getAddress(sPublicKey));
out.print("<p>toChecksumAddress= " + Keys.toChecksumAddress(Keys.getAddress(sPublicKey)));
out.print("<p>" + byte2Hex(Keys.getAddress(hex2Byte(sPublicKey))));

BigInteger biPrivateKey = new BigInteger(hex2Byte(sPublicKey));
BigInteger biPublicKey = new BigInteger(hex2Byte(byte2Hex(bPublicKey).substring(2)));
ECKeyPair kp = new ECKeyPair(biPrivateKey, biPublicKey);
//out.print("<p>BigInteger to address= " + Keys.getAddress(biPublicKey));
//out.print("<p>deserialize address= " + Keys.getAddress(kp));

/*
String	myEthereumAddress = byte2Hex(org.ethereum.crypto.ECKey.fromPublicOnly(hex2Byte(sPublicKey)).getAddress());
sResponse += "<p>myEthereumAddress= " + myEthereumAddress;
*/

out.print(sResponse);
out.flush();

//writeLog("debug", obj.toString());
%>

<%!
/*
	//將 16 進位碼的字串轉為 byte array
	public static byte[] hex2Byte(String hexString) {
	        byte[] bytes = new byte[hexString.length() / 2];
	        for (int i=0 ; i<bytes.length ; i++)
	                bytes[i] = (byte) Integer.parseInt(hexString.substring(2 * i, 2 * i + 2), 16);
	        return bytes;
	}

    //取得 byte array 每個 byte 的 16 進位碼
    public static String byte2Hex(byte[] b) {
        String result = "";
        for (int i=0 ; i<b.length ; i++)
            result += Integer.toString( ( b[i] & 0xff ) + 0x100, 16).substring( 1 );
        return result;
    }

*/
%>