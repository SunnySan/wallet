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

String txHash			= nullToString(request.getParameter("txHash"), "");
String address			= nullToString(request.getParameter("address"), "");
String publicKey			= nullToString(request.getParameter("publicKey"), "");
String currencyId			= nullToString(request.getParameter("currencyId"), "");
String sig			= nullToString(request.getParameter("sig"), "");

writeLog("debug", "txHash= " + txHash);
writeLog("debug", "address= " + address);
writeLog("debug", "publicKey= " + publicKey);
writeLog("debug", "currencyId= " + currencyId);
writeLog("debug", "sig= " + sig);

if (beEmpty(txHash)){
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
	return;
}

String	sResponse	=	"";
String unsignedHash = txHash;
String		sResultCode			= gcResultCodeSuccess;
String		sResultText			= gcResultTextSuccess;

String[] aSig = sig.split(",");

NetworkParameters params = null;
if (currencyId.equals("BTC")) params = NetworkParameters.fromID(NetworkParameters.ID_MAINNET);
else params = NetworkParameters.fromID(NetworkParameters.ID_TESTNET);

Address myAddress = Address.fromString(params, address);

Transaction tx = new Transaction(params, hex2Byte(unsignedHash));

for (int i = 0; i < tx.getInputs().size(); i++) {
	TransactionInput transactionInput = tx.getInput(i);
	Script scriptPubKey = ScriptBuilder.createOutputScript(Address.fromString(params, address));
	
	ECKey.ECDSASignature sig1 = ECKey.ECDSASignature.decodeFromDER(hex2Byte(aSig[i]));
	sig1 = sig1.toCanonicalised();
	
	TransactionSignature txSig = null;
	
	txSig = new TransactionSignature(sig1, Transaction.SigHash.ALL, true);

	/*
	txSig = new TransactionSignature(ECKey.ECDSASignature.decodeFromDER(hex2Byte(aSig[i])), Transaction.SigHash.ALL, true);
	txSig = txSig.toCanonicalised();
	*/

	if (scriptPubKey.isSentToRawPubKey()) {
		//transactionInput.setScriptSig(ScriptBuilder.createInputScript(txSig));
		//transactionInput.setScriptSig(Script.createInputScript(hex2Byte("3045022100B04EA8A8E84364455DADEA51A5064FC7F33D8B559F45C04F06F179C9D0C9B38C02206BE340B3B593BCE4CC6C0F6584F44FD9EDFEEA862421E9B9B16E1694C6170222")));
		transactionInput.setScriptSig(ScriptBuilder.createInputScript(txSig));
	} else {
		if (!scriptPubKey.isSentToAddress()) {
			out.println("<p>Don't know how to sign for this kind of scriptPubKey: " + scriptPubKey);
		}
		//transactionInput.setScriptSig(ScriptBuilder.createInputScript(txSig, ecKey));
		//transactionInput.setScriptSig(Script.createInputScript(hex2Byte("304502207D409BB4FE330BE29B993DEA81A0EDA90FC8D57B28571AE8077F2144E6A5DFF7022100FE25C18C2589DC93EFF1F86414CAD61F5B33969F034AF9095B2AF526110F7CA4"), hex2Byte(sPublicKey)));
		transactionInput.setScriptSig(ScriptBuilder.createInputScript(txSig, ECKey.fromPublicOnly(hex2Byte(publicKey))));
	}
}
tx.verify();
String valueToSend = byte2Hex(tx.bitcoinSerialize());

obj.put("txHex", valueToSend);











obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);

out.print(obj);
out.flush();






/*
Address targetAddress = Address.fromString(params, "mzXuJo757JoxpiGqdwGiBu9BMWbto1PaAx");
ECKey myKey = ECKey.fromPublicOnly(hex2Byte("03B4CFEEB44B6D0A2E8FAB410FD70FA1646DA7BE47C6B559349EA7513143BF7D54"));
Wallet myWallet = Wallet.createBasic(params);
myWallet.importKey(myKey);

Address myAddress = Address.fromString(params, "mjDsHBSbwouL1H8fzp7onN2BcC1rWLobGZ");
//Coin addressBalance = Wallet.getBalance(new AddressBalance(myAddress));
//CoinSelector cs = new AddressBalance(myAddress);
//Coin addressBalance = Wallet.getBalance(cs);
//out.print("<p>balance coin: " + String.valueOf(addressBalance.getValue()));

long myBalance = myWallet.getBalance().getValue();
out.print("<p>balance: " + String.valueOf(myBalance));

java.util.List<TransactionOutput> unspents = myWallet.getUnspents();
for (TransactionOutput unspent : unspents) {
	Coin unspentCoin = unspent.getValue();
	long unspentValue = unspentCoin.getValue();
	out.print("<p>unspent: " + String.valueOf(unspentValue));
}






tx.addOutput(Coin.valueOf(1L), targetAddress);

TransactionInput transactionInput = new TransactionInput(params, tx, hex2Byte("03B4CFEEB44B6D0A2E8FAB410FD70FA1646DA7BE47C6B559349EA7513143BF7D54"));
tx.addInput(transactionInput);
out.print("<p>TX:<p>" + tx.toString());

    for (int i = 0; i < tx.getInputs().size(); i++) {
        Script scriptPubKey = ScriptBuilder.createOutputScript(myAddress);
        Sha256Hash hash = tx.hashForSignature(i, scriptPubKey, Transaction.SigHash.ALL, true);
        out.print("<p>hash:<p>" + byte2Hex(hash.getBytes()));
    }

ECKey.ECDSASignature ecdsaSignature = ECDSASignature.decodeFromDER(hex2Byte("3046022100B205751BB2C4F4352145E833AF28D2444C54F267A41C880176435B845EF4547D0221009A04AF6B4E7E72728CECE8721E4EE0EE1C5D074FCD5EEFB3D953A977E210A77C"));
TransactionSignature txSignature = new TransactionSignature(ecdsaSignature, Transaction.SigHash.ALL, true);
tx.getInput(0).setScriptSig(ScriptBuilder.createInputScript(txSignature));
tx.verify();
String hex = byte2Hex(tx.bitcoinSerialize());
out.print("<p>tx bitcoinSerialize:<p>" + hex);
*/

/*
addInputsToTransaction(myAddress, tx, unspents, amount);
signInputsOfTransaction(myAddress, tx, key);

tx.verify();
tx.getConfidence().setSource(TransactionConfidence.Source.SELF);
tx.setPurpose(Transaction.Purpose.USER_PAYMENT);
String valueToSend = byteArrayToHexString(tx.bitcoinSerialize());
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