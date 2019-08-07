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

<%@page import="org.web3j.protocol.Web3j" %>
<%@page import="org.web3j.protocol.core.JsonRpc2_0Web3j" %>
<%@page import="org.web3j.protocol.http.HttpService" %>
<%@page import="org.web3j.protocol.core.DefaultBlockParameterName" %>

<%@page import="org.web3j.protocol.core.methods.response.EthGetTransactionCount" %>
<%@page import="org.web3j.protocol.core.methods.response.EthSendTransaction" %>



<%@page import="org.ethereum.core.Transaction" %>
<%@page import="org.ethereum.util.ByteUtil" %>
<%@page import="org.apache.commons.codec.binary.Hex" %>
<%@page import="org.bouncycastle.math.ec.ECPoint" %>
<%@page import="org.bouncycastle.math.ec.ECCurve" %>
<%@page import="org.bouncycastle.jce.spec.ECParameterSpec" %>
<%@page import="org.bouncycastle.asn1.*" %>
<%@page import="org.bouncycastle.asn1.sec.SECNamedCurves" %>
<%@page import="org.bouncycastle.asn1.x9.X9ECParameters" %>
<%@page import="org.bouncycastle.asn1.x9.X9IntegerConverter" %>
<%@page import="org.bouncycastle.crypto.ec.CustomNamedCurves" %>
<%@page import="org.bouncycastle.crypto.params.ECDomainParameters" %>
<%@page import="org.bouncycastle.math.ec.ECAlgorithms" %>
<%@page import="org.bouncycastle.math.ec.ECPoint" %>
<%@page import="org.bouncycastle.math.ec.FixedPointCombMultiplier" %>
<%@page import="org.bouncycastle.math.ec.custom.sec.SecP256K1Curve" %>


<%@ page import="java.math.BigInteger"%>

<%@include file="00_constants.jsp"%>
<%@include file="00_utility.jsp"%>

<%
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
response.setHeader("Pragma","no-cache"); 
response.setHeader("Cache-Control","no-cache"); 
response.setDateHeader("Expires", 0); 

out.clear();	//注意，一定要有out.clear();，要不然client端無法解析XML，會認為XML格式有問題

JSONObject	obj=new JSONObject();

String	sResponse	= "";

/*********************開始做事吧*********************/

String cardId		= nullToString(request.getParameter("cardId"), "");
String signature	= nullToString(request.getParameter("data"), "");
String src			= nullToString(request.getParameter("src"), "");

if (beEmpty(cardId) || beEmpty(signature)){
	writeLog("debug", "BIP push signed ETH/ETHTEST transaction parameter not found for Card_Id= " + cardId + ", signature=" + signature);
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
	return;
}else{
	writeLog("debug", "BIP push signed ETH/ETHTEST transaction for Card_Id= " + cardId + ", signature=" + signature);
}

Hashtable	ht					= new Hashtable();
String		sResultCode			= gcResultCodeSuccess;
String		sResultText			= gcResultTextSuccess;
String		sa[][]				= null;
String		sSQL				= "";
List<String> sSQLList			= new ArrayList<String>();
String		sDate				= getDateTimeNow(gcDateFormatSlashYMDTime);
String		sUser				= "System";

String		ss					= "";
int			i					= 0;
int			j					= 0;
int			k					= 0;
int			l					= 0;

String	currencyId				= "";
String	unsignedHash			= "";
String	jobRowId				= "";
String	transactionRowId		= "";
String	address					= "";
String	publicKey				= "";
java.lang.Boolean	bOK			= false;
String	txid					= "";
String	valueToSend				= "";

String ethApiEndPoint = "";
String senderAddress = "";
String senderPublicKey = "";
String toAddress = "";
String sAmount = "";
String sGasPrice = "";
String sMessageHash = "";


sSQL = "SELECT A.id, B.id, B.Currency_Id, B.To_Address, B.Amount, B.Transaction_Fee, B.Hash_To_Be_Signed, C.Address, C.Publicy_Key";
sSQL += " FROM cwallet_bip_job_queue A, cwallet_transaction B, cwallet_wallet_currency C";
sSQL += " WHERE A.Card_Id='" + cardId + "'";
sSQL += " AND A.CMD='" + "50" + "'";
if (notEmpty(src) && src.equals("web")){
	sSQL += " AND (A.Status='" + "Init" + "' OR A.Status='" + "Sync" + "')";
}else{
	sSQL += " AND A.Status='" + "Sync" + "'";
}
sSQL += " AND A.Transaction_Id=B.Transaction_Id";
sSQL += " AND C.Card_Id='" + cardId + "'";
sSQL += " AND C.Wallet_Id=B.Wallet_Id";
sSQL += " AND C.Currency_Id=B.Currency_Id";
sSQL += " ORDER BY A.id desc";
sSQL += " LIMIT 1";

ht = getDBData(sSQL, gcDataSourceNameCMSIOT);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	sa = (String[][])ht.get("Data");
	jobRowId = sa[0][0];
	transactionRowId = sa[0][1];
	currencyId = sa[0][2];
	toAddress = sa[0][3];
	sAmount = sa[0][4];
	sGasPrice = sa[0][5];
	sMessageHash = sa[0][6];
	senderAddress = sa[0][7];
	senderPublicKey = sa[0][8];
}else{
	writeLog("error", "BIP push signed ETH/ETHTEST transaction failed, sResultCode= " + sResultCode + ", sResultText= " + sResultText);
	obj.put("resultCode", sResultCode);
	obj.put("resultText", sResultText);
	out.print(obj);
	out.flush();
	return;
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

float f = Float.parseFloat(sGasPrice);
f = f * 1000000000;
long lGasPrice = (long)f;
writeLog("debug", "Gas Price (GWei)= " + sGasPrice);
writeLog("debug", "Gas Price (Wei)= " + String.valueOf(lGasPrice));

long lGasLimit = 400000;
writeLog("debug", "Gas Limit (Wei)= " + String.valueOf(lGasLimit));

writeLog("debug", "Amount (ETH)= " + sAmount);
double d = Double.parseDouble(sAmount);
d = d * Double.parseDouble("1000000000000000000");
long lAmount = (long)d;
writeLog("debug", "Amount (Wei)= " + String.valueOf(lAmount));

//將 SIM 卡算出的 compressed public key 解壓縮，得到未被 compress 的 public key
org.bitcoinj.core.ECKey pubKey = org.bitcoinj.core.ECKey.fromPublicOnly(hex2Byte(senderPublicKey));
org.bitcoinj.core.ECKey decompressedPubKey = pubKey.decompress();
byte[] baDecompressedPubKey = decompressedPubKey.getPubKey();
writeLog("debug", "senderPublicKey= " + senderPublicKey);
writeLog("debug", "Decompressed senderPublicKey= " + byte2Hex(baDecompressedPubKey));

//從未被 compress 的 public key 算出以太鏈的 address
byte[] baAddress = org.ethereum.crypto.ECKey.computeAddress(baDecompressedPubKey);
senderAddress = byte2Hex(baAddress);
writeLog("debug", "senderAddress= " + senderAddress);

//注意：ETH mainnet chainId = 1, ropsten testnet chainId = 3
Integer chainId = 3;
if (currencyId.equals("ETH")){
	ethApiEndPoint = "https://mainnet.infura.io/v3/1a2cc5dffd8b46699947c7a73d152380";	//mainnet testnet
	chainId = 1;
}else{
	ethApiEndPoint = "https://ropsten.infura.io/v3/1a2cc5dffd8b46699947c7a73d152380";	//ropsten testnet
	chainId = 3;
}

//取得 Web3j 服務
//Web3j web3j = Web3j.build(new HttpService(ethApiEndPoint));	//這個寫法只能用於 JAVA 1.8以上
Web3j web3j = new JsonRpc2_0Web3j(new HttpService(ethApiEndPoint));


//取得sender address的 nonce
EthGetTransactionCount ethGetTransactionCount = web3j.ethGetTransactionCount(
             (senderAddress.startsWith("0x")?senderAddress:"0x"+senderAddress), DefaultBlockParameterName.LATEST).sendAsync().get();
BigInteger nonce = ethGetTransactionCount.getTransactionCount();
writeLog("debug", "nonce=" + nonce);

//填入 SIM 卡送來的簽名
String sSignatureData = signature;
writeLog("debug", "SIM signature= " + sSignatureData);

//將簽名做 Canonicalised
org.bitcoinj.core.ECKey.ECDSASignature sig = org.bitcoinj.core.ECKey.ECDSASignature.decodeFromDER(hex2Byte(sSignatureData));
sig = sig.toCanonicalised();
sSignatureData = byte2Hex(sig.encodeToDER());

writeLog("debug", "toCanonicalised signature= " + sSignatureData);

//找出 signature 中的 r, s 值
BigInteger br, bs;
ASN1InputStream decoder = null;
try {
	decoder = new ASN1InputStream(hex2Byte(sSignatureData));
	DLSequence seq = (DLSequence) decoder.readObject();
	if (seq == null){
		writeLog("error", "sSignatureData is invalid, reached past end of ASN.1 stream.");
		obj.put("resultCode", gcResultCodeUnknownError);
		obj.put("resultText", "Invalid signature data");
		out.print(obj);
		out.flush();
		return;
	}else{
		ASN1Integer r, s;
		try {
			r = (ASN1Integer) seq.getObjectAt(0);
			s = (ASN1Integer) seq.getObjectAt(1);
		} catch (ClassCastException e) {
			throw new IllegalArgumentException(e);
		}
		// OpenSSL deviates from the DER spec by interpreting these values as unsigned, though they should not be
		// Thus, we always use the positive versions. See: http://r6.ca/blog/20111119T211504Z.html
		br = r.getPositiveValue();
		bs = s.getPositiveValue();
	}
} catch (IOException e) {
	writeLog("error", "Exception while parsing signature data: " + e.toString());
	obj.put("resultCode", gcResultCodeUnknownError);
	obj.put("resultText", "Exception while parsing signature data.");
	out.print(obj);
	out.flush();
	return;
} finally {
	if (decoder != null)
	try { decoder.close(); } catch (IOException x) {}
}

//找出 v 值
org.ethereum.crypto.ECKey.ECDSASignature ejSignature = org.ethereum.crypto.ECKey.ECDSASignature.decodeFromDER(sig.encodeToDER()); 
// Now we have to work backwards to figure out the recId needed to recover the signature.
int recId = getRecId(ejSignature, hex2Byte(sMessageHash), baDecompressedPubKey, hex2Byte(senderPublicKey));
if (recId == -1) {
	writeLog("error", "Couldn't find correct public key from signature.");
	obj.put("resultCode", gcResultCodeUnknownError);
	obj.put("resultText", "Couldn't find correct public key from signature.");
	out.print(obj);
	out.flush();
	return;
}
int headerByte = recId + 27;

//準備好 r, s, v
byte[] baR, baS;
baR = br.toByteArray();
baS = bs.toByteArray();
byte v = (byte) headerByte;

writeLog("debug", "r=" + byte2Hex(baR));
writeLog("debug", "s=" + byte2Hex(baS));

//用 r, s, v 建立已被簽名的 Transaction 物件
Transaction tx2 = new Transaction(
        ByteUtil.bigIntegerToBytes(nonce),
        ByteUtil.longToBytesNoLeadZeroes(lGasPrice),
        ByteUtil.longToBytesNoLeadZeroes(lGasLimit),
        hex2Byte(toAddress.startsWith("0x") || toAddress.startsWith("0X")?toAddress.substring(2):toAddress),
        ByteUtil.bigIntegerToBytes(BigInteger.valueOf(lAmount)),
        null,
        baR,
        baS,
        v,
        chainId);

//tx2.getEncoded() 就是要送到以太鏈上的 raw transaction
valueToSend = byte2Hex(tx2.getEncoded());
writeLog("debug", "Raw transaction getEncoded: 0x{}=" + valueToSend);

//使用 Web3j 將 raw transaction 送出，並取得交易 id

EthSendTransaction ethSendTransaction = web3j.ethSendRawTransaction("0x" + byte2Hex(tx2.getEncoded())).sendAsync().get();
if (ethSendTransaction.hasError()) {
	writeLog("error", "Error while sending raw transaction to blockchain: " + ethSendTransaction.getError().getMessage());
	sResultCode	= gcResultCodeUnknownError;
	sResultText	= "Error while sending raw transaction to blockchain";
}else{
	txid = ethSendTransaction.getTransactionHash();
	writeLog("debug", "Raw transaction hash id= " + txid);
	bOK = true;
}


if (bOK){
	sSQL = "UPDATE cwallet_bip_job_queue";
	sSQL += " SET Status='Success'";
	sSQL += " WHERE id=" + jobRowId;
	sSQLList.add(sSQL);
	sSQL = "UPDATE cwallet_transaction";
	sSQL += " SET Status='Success'";
	sSQL += " ,Blockchain_Tx_Id='" + txid + "'";
	sSQL += " ,Signed_Hex='" + valueToSend + "'";
	sSQL += " WHERE id=" + transactionRowId;
	sSQLList.add(sSQL);
	sResultCode	= gcResultCodeSuccess;
	sResultText	= gcResultTextSuccess;
}else{
	sSQL = "UPDATE cwallet_bip_job_queue";
	sSQL += " SET Status='Fail'";
	sSQL += " WHERE id=" + jobRowId;
	sSQLList.add(sSQL);
	sSQL = "UPDATE cwallet_transaction";
	sSQL += " SET Status='Fail'";
	sSQL += " ,Signed_Hex='" + valueToSend + "'";
	sSQL += " WHERE id=" + transactionRowId;
	sSQLList.add(sSQL);
}
ht = updateDBData(sSQLList, gcDataSourceNameCMSIOT, false);

obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
writeLog("debug", "Response message= " + obj.toString());
out.print(obj);
out.flush();
%>

<%!
    public static final ECDomainParameters CURVE;
    public static final ECParameterSpec CURVE_SPEC;
    static {
        // All clients must agree on the curve to use by agreement. Ethereum uses secp256k1.
        X9ECParameters params = SECNamedCurves.getByName("secp256k1");
        CURVE = new ECDomainParameters(params.getCurve(), params.getG(), params.getN(), params.getH());
        CURVE_SPEC = new ECParameterSpec(params.getCurve(), params.getG(), params.getN(), params.getH());
        HALF_CURVE_ORDER = params.getN().shiftRight(1);
    }
    
    public static X9ECParameters CURVE_PARAMS = CustomNamedCurves.getByName("secp256k1");
    static BigInteger HALF_CURVE_ORDER = CURVE_PARAMS.getN().shiftRight(1);
    
    public int getRecId(org.ethereum.crypto.ECKey.ECDSASignature messageSignature, byte[] messageHash, byte[] noCompressedKey, byte[] compressedKey){
		int recId = -1;
		for (int i = 0; i < 4; i++) {
			byte[] k = recoverPubBytesFromSignature(i, messageSignature, messageHash);
			if (k!=null)writeLog("debug", "i= " + String.valueOf(i) + ", k= " + byte2Hex(k));
			if (k != null && (Arrays.equals(k, noCompressedKey) || Arrays.equals(k, compressedKey))) {
				recId = i;
				break;
			}
		}
		return recId;
    }

    public static byte[] recoverPubBytesFromSignature(int recId, org.ethereum.crypto.ECKey.ECDSASignature sig, byte[] messageHash) {
        if(!(recId >= 0)) return null;;
        if(!(sig.r.signum() >= 0)) return null;;
        if(!(sig.s.signum() >= 0)) return null;;
        if(!(messageHash != null)) return null;;

        // 1.0 For j from 0 to h   (h == recId here and the loop is outside this function)
        //   1.1 Let x = r + jn
        BigInteger n = CURVE.getN();  // Curve order.
        BigInteger i = BigInteger.valueOf((long) recId / 2);
        BigInteger x = sig.r.add(i.multiply(n));
        //   1.2. Convert the integer x to an octet string X of length mlen using the conversion routine
        //        specified in Section 2.3.7, where mlen = ⌈(log2 p)/8⌉ or mlen = ⌈m/8⌉.
        //   1.3. Convert the octet string (16 set binary digits)||X to an elliptic curve point R using the
        //        conversion routine specified in Section 2.3.4. If this conversion routine outputs “invalid”, then
        //        do another iteration of Step 1.
        //
        // More concisely, what these points mean is to use X as a compressed public key.
        ECCurve.Fp curve = (ECCurve.Fp) CURVE.getCurve();
        BigInteger prime = curve.getQ();  // Bouncy Castle is not consistent about the letter it uses for the prime.
        if (x.compareTo(prime) >= 0) {
            // Cannot have point co-ordinates larger than this as everything takes place modulo Q.
            return null;
        }
        // Compressed keys require you to know an extra bit of data about the y-coord as there are two possibilities.
        // So it's encoded in the recId.
        ECPoint R = decompressKey(x, (recId & 1) == 1);
        //   1.4. If nR != point at infinity, then do another iteration of Step 1 (callers responsibility).
        if (!R.multiply(n).isInfinity())
            return null;
        //   1.5. Compute e from M using Steps 2 and 3 of ECDSA signature verification.
        BigInteger e = new BigInteger(1, messageHash);
        //   1.6. For k from 1 to 2 do the following.   (loop is outside this function via iterating recId)
        //   1.6.1. Compute a candidate public key as:
        //               Q = mi(r) * (sR - eG)
        //
        // Where mi(x) is the modular multiplicative inverse. We transform this into the following:
        //               Q = (mi(r) * s ** R) + (mi(r) * -e ** G)
        // Where -e is the modular additive inverse of e, that is z such that z + e = 0 (mod n). In the above equation
        // ** is point multiplication and + is point addition (the EC group operator).
        //
        // We can find the additive inverse by subtracting e from zero then taking the mod. For example the additive
        // inverse of 3 modulo 11 is 8 because 3 + 8 mod 11 = 0, and -3 mod 11 = 8.
        BigInteger eInv = BigInteger.ZERO.subtract(e).mod(n);
        BigInteger rInv = sig.r.modInverse(n);
        BigInteger srInv = rInv.multiply(sig.s).mod(n);
        BigInteger eInvrInv = rInv.multiply(eInv).mod(n);
        ECPoint.Fp q = (ECPoint.Fp) ECAlgorithms.sumOfTwoMultiplies(CURVE.getG(), eInvrInv, R, srInv);
        // result sanity check: point must not be at infinity
        if (q.isInfinity())
            return null;
        return q.getEncoded();
    }

    private static ECPoint decompressKey(BigInteger xBN, boolean yBit) {
        X9IntegerConverter x9 = new X9IntegerConverter();
        byte[] compEnc = x9.integerToBytes(xBN, 1 + x9.getByteLength(CURVE.getCurve()));
        compEnc[0] = (byte) (yBit ? 0x03 : 0x02);
        return CURVE.getCurve().decodePoint(compEnc);
    }

%>