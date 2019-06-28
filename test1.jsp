<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@page import="java.net.InetAddress" %>
<%@page import="org.json.simple.JSONObject" %>
<%@page import="org.json.simple.parser.JSONParser" %>
<%@page import="org.json.simple.parser.ParseException" %>
<%@page import="org.json.simple.JSONArray" %>
<%@page import="org.apache.commons.io.IOUtils" %>
<%@page import="java.util.*" %>


<%@ page import="org.ethereum.crypto.ECKey"%>
<%@ page import="org.ethereum.core.*"%>
<%@ page import="org.ethereum.crypto.HashUtil"%>
<%@ page import="org.ethereum.db.ByteArrayWrapper"%>
<%@ page import="org.ethereum.facade.EthereumFactory"%>
<%@ page import="org.ethereum.listener.EthereumListenerAdapter"%>
<%@ page import="org.ethereum.util.ByteUtil"%>
<%@ page import="org.ethereum.util.blockchain.EtherUtil"%>
<%@ page import="org.spongycastle.util.encoders.Hex"%>
<%@ page import="java.math.BigInteger"%>
<%@ page import="java.util.Collections"%>
<%@ page import="java.util.HashMap"%>
<%@ page import="java.util.List"%>
<%@ page import="java.util.Map"%>

<%@ page import="org.bouncycastle.jcajce.provider.digest.Keccak"%>
<%@ page import="org.web3j.utils.Numeric"%>

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

out.print(byte2Hex(HashUtil.sha3(hex2Byte(sPublicKey))));
/*
String	myEthereumAddress = byte2Hex(org.ethereum.crypto.ECKey.fromPublicOnly(hex2Byte(sPublicKey)).getAddress());
sResponse += "<p>myEthereumAddress= " + myEthereumAddress;
*/

out.print(sResponse);
out.flush();

//writeLog("debug", obj.toString());
%>

<%!

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

    /**
     * Keccak-256 hash function.
     *
     * @param hexInput hex encoded input data with optional 0x prefix
     * @return hash value as hex encoded string
     */
    public static String sha3(String hexInput) {
        byte[] bytes = Numeric.hexStringToByteArray(hexInput);
        byte[] result = sha3(bytes);
        return Numeric.toHexString(result);
    }

    /**
     * Keccak-256 hash function.
     *
     * @param input binary encoded input data
     * @return hash value
     */
    public static byte[] sha3(byte[] input) {
        return sha3(input, 0, input.length);
    }

    /**
     * Keccak-256 hash function.
     *
     * @param input binary encoded input data
     * @param offset of start of data
     * @param length of data
     * @return hash value
     */
    public static byte[] sha3(byte[] input, int offset, int length) {
        Keccak.DigestKeccak kecc = new Keccak.Digest256();
        kecc.update(input, offset, length);
        return kecc.digest();
    }


%>