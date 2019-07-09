<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
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
<%@ page import="org.bitcoinj.core.TransactionOutput"%>
<%@ page import="org.bitcoinj.core.TransactionInput"%>
<%@ page import="org.bitcoinj.core.Transaction"%>
<%@ page import="org.bitcoinj.core.Base58"%>
<%@ page import="org.bitcoinj.core.Sha256Hash"%>
<%@ page import="org.bitcoinj.core.Address"%>
<%@ page import="org.bitcoinj.core.Coin"%>
<%@ page import="org.bitcoinj.core.NetworkParameters"%>
<%@ page import="org.bitcoinj.wallet.Wallet"%>
<%@ page import="org.bitcoinj.core.Sha256Hash"%>
<%@ page import="org.bitcoinj.core.ECKey.ECDSASignature"%>
<%@ page import="org.bitcoinj.crypto.TransactionSignature"%>
<%@ page import="org.bitcoinj.script.Script"%>
<%@ page import="java.math.BigInteger"%>

<%@ page import="org.bouncycastle.asn1.*"%>
<%@ page import="org.bouncycastle.asn1.util.ASN1Dump"%>
<%@ page import="java.io.ByteArrayInputStream"%>




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
String s1 = "3046022100fdd65dad87f8583d2fec6f9251cf8c4ba78063c036013fc5f17a77c58b6825d0022100a1e3f5c6fa3ad96bcd32c72a66f007674f56ca3b09d88370f28dde3aa88d011901";
ECKey.ECDSASignature sig = ECDSASignature.decodeFromDER(hex2Byte(s1));
ECKey.ECDSASignature sig2 = sig.toCanonicalised();
String s2 = byte2Hex(sig2.encodeToDER());

out.println(s2 + "<p>");

String r = "00fdd65dad87f8583d2fec6f9251cf8c4ba78063c036013fc5f17a77c58b6825d0";
String s = "00a1e3f5c6fa3ad96bcd32c72a66f007674f56ca3b09d88370f28dde3aa88d0119";
/*
ASN1InputStream bIn = new ASN1InputStream(new ByteArrayInputStream(r.getBytes()));
ASN1Primitive objR = bIn.readObject();
out.println(ASN1Dump.dumpAsString(objR) + "<p>");
*/




/*
BigInteger br = new BigInteger(r,16);
BigInteger bs = new BigInteger(s,16);


int i = bs.compareTo(br.divide(BigInteger.valueOf(2)));	//小於則返回-1，等於則返回0，大於則返回1
out.println(String.valueOf(i) + "<p>");

BigInteger bs2 = br.subtract(bs);
String s2 = byte2Hex(bs2.toByteArray());
out.println(s2);
*/


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



//https://bitcoin.stackexchange.com/questions/81376/how-do-i-sign-and-send-a-raw-transaction-using-bitcoinj
/*
private void addInputsToTransaction(Address sourceAddress, Transaction tx, @NonNull BalanceResponse.Unspents[] unspents, Long amount) {
    long gatheredAmount = 0L;
    long requiredAmount = amount + TX_FEE;
    for (BalanceResponse.Unspents unspent : unspents) {
        gatheredAmount += unspent.getAmount();
        TransactionOutPoint outPoint = new TransactionOutPoint(networkParams, unspent.getvOut(), Sha256Hash.wrap(unspent.getTxId()));
        TransactionInput transactionInput = new TransactionInput(networkParams, tx, hexStringToByteArray(unspent.getScriptPubKey()),
                outPoint, Coin.valueOf(unspent.getAmount());
        tx.addInput(transactionInput);

        if (gatheredAmount >= requiredAmount) {
            break;
        }
    }
    if (gatheredAmount > requiredAmount) {
        //return change to sender, in real life it should use different address
        tx.addOutput(Coin.valueOf((gatheredAmount - requiredAmount)), sourceAddress);
    }
}

private void signInputsOfTransaction(Address sourceAddress, @NonNull Transaction tx, ECKey key) {
    for (int i = 0; i < tx.getInputs().size(); i++) {
        Script scriptPubKey = ScriptBuilder.createOutputScript(sourceAddress);
        Sha256Hash hash = tx.hashForSignature(i, scriptPubKey, Transaction.SigHash.ALL, true);
        ECKey.ECDSASignature ecdsaSignature = key.sign(hash);
        TransactionSignature txSignature = new TransactionSignature(ecdsaSignature, Transaction.SigHash.ALL, true);

        if (ScriptPattern.isP2PK(scriptPubKey)) {
            tx.getInput(i).setScriptSig(ScriptBuilder.createInputScript(txSignature));
        } else {
            if (!ScriptPattern.isP2PKH(scriptPubKey)) {
                throw new ScriptException(ScriptError.SCRIPT_ERR_UNKNOWN_ERROR, "Unable to sign this scrptPubKey: " + scriptPubKey);
            }
            tx.getInput(i).setScriptSig(ScriptBuilder.createInputScript(txSignature, key));
        }
    }
}
*/

%>