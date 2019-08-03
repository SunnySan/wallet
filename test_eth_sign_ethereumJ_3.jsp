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
String ethApiEndPoint = "https://ropsten.infura.io/v3/1a2cc5dffd8b46699947c7a73d152380";	//ropsten testnet
String senderAddress = "0xb2ab932d6983b8637b274ad66256fedcbf0e32a7";
String senderPublicKey = "0285AB5095F0F70E0C9118B0DE9764AE96F8773A29DB54235A989E4C06A2165F83";
String toAddress = "65D28726cFA311F80e2C02608185C9900861aad7";

//將 SIM 卡算出的 compressed public key 解壓縮，得到未被 compress 的 public key
org.bitcoinj.core.ECKey pubKey = org.bitcoinj.core.ECKey.fromPublicOnly(hex2Byte(senderPublicKey));
org.bitcoinj.core.ECKey decompressedPubKey = pubKey.decompress();
byte[] baDecompressedPubKey = decompressedPubKey.getPubKey();
writeLog("debug", "baDecompressedPubKey= " + byte2Hex(baDecompressedPubKey));

//從未被 compress 的 public key 算出以太鏈的 address
byte[] baAddress = org.ethereum.crypto.ECKey.computeAddress(baDecompressedPubKey);
senderAddress = byte2Hex(baAddress);
out.println("<p>senderAddress=" + senderAddress);



//取得 Web3j 服務
Web3j web3j = Web3j.build(new HttpService(ethApiEndPoint));

//取得sender address的 nonce
EthGetTransactionCount ethGetTransactionCount = web3j.ethGetTransactionCount(
             (senderAddress.startsWith("0x")?senderAddress:"0x"+senderAddress), DefaultBlockParameterName.LATEST).sendAsync().get();
BigInteger nonce = ethGetTransactionCount.getTransactionCount();
out.println("<p>nonce=" + nonce);

//注意：ETH mainnet chainId = 1, ropsten testnet chainId = 3
Integer chainId = 3;

//建立未被簽名的 Transaction 物件
Transaction tx = new Transaction(
        ByteUtil.bigIntegerToBytes(nonce),
        ByteUtil.longToBytesNoLeadZeroes(2),
        ByteUtil.longToBytesNoLeadZeroes(200000),
        hex2Byte(toAddress),
        ByteUtil.bigIntegerToBytes(BigInteger.valueOf(1)),  // 1 gwei
        null,
        chainId);
byte[] messageHash = tx.getRawHash();	//須被簽名的 hash
out.println("<p>messageHash=" + byte2Hex(messageHash));

//填入 SIM 卡送來的簽名
String sSignatureData = "30460221008D2846159026EC57553AA1517A6EB0502377498549A35D9379434FFA6C22FFC9022100F49A992A691E6A8F9F81C6BE0103D9D1C881C62CFD6FCC277738BE6FF4EA07C2";
out.println("<p>SIM signature=" + sSignatureData);

//將簽名做 Canonicalised
org.bitcoinj.core.ECKey.ECDSASignature sig = org.bitcoinj.core.ECKey.ECDSASignature.decodeFromDER(hex2Byte(sSignatureData));
sig = sig.toCanonicalised();
sSignatureData = byte2Hex(sig.encodeToDER());

out.println("<p>toCanonicalised signature=" + sSignatureData);

//找出 signature 中的 r, s 值
BigInteger br, bs;
ASN1InputStream decoder = null;
try {
	decoder = new ASN1InputStream(hex2Byte(sSignatureData));
	DLSequence seq = (DLSequence) decoder.readObject();
	if (seq == null)
	throw new RuntimeException("Reached past end of ASN.1 stream.");
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
} catch (IOException e) {
	throw new RuntimeException(e);
} finally {
	if (decoder != null)
	try { decoder.close(); } catch (IOException x) {}
}

//找出 v 值
org.ethereum.crypto.ECKey.ECDSASignature ejSignature = org.ethereum.crypto.ECKey.ECDSASignature.decodeFromDER(sig.encodeToDER()); 
// Now we have to work backwards to figure out the recId needed to recover the signature.
int recId = getRecId(ejSignature, messageHash, baDecompressedPubKey, hex2Byte(senderPublicKey));
if (recId == -1) {
	out.println("<p>Couldn't find correct public key from signature");
	return;
}
int headerByte = recId + 27;

//準備好 r, s, v
byte[] baR, baS;
baR = br.toByteArray();
baS = bs.toByteArray();
byte v = (byte) headerByte;

out.println("<p>r=" + byte2Hex(baR));
out.println("<p>s=" + byte2Hex(baS));

//用 r, s, v 建立已被簽名的 Transaction 物件
Transaction tx2 = new Transaction(
        ByteUtil.bigIntegerToBytes(nonce),
        ByteUtil.longToBytesNoLeadZeroes(2),
        ByteUtil.longToBytesNoLeadZeroes(200000),
        hex2Byte(toAddress),
        ByteUtil.bigIntegerToBytes(BigInteger.valueOf(1)),  // 1 gwei
        null,
        baR,
        baS,
        v,
        chainId);

//tx2.getEncoded() 就是要送到以太鏈上的 raw transaction
out.println("<p>Raw transaction getEncoded: 0x{}=" + byte2Hex(tx2.getEncoded()));

//使用 Web3j 將 raw transaction 送出，並取得交易 id
EthSendTransaction ethSendTransaction = web3j.ethSendRawTransaction(byte2Hex(tx2.getEncoded())).sendAsync().get();
String transactionHash = ethSendTransaction.getTransactionHash();
out.println("<p>Raw transaction hash id=" + transactionHash);
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