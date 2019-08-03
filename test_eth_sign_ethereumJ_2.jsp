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

<%@page import="org.bouncycastle.asn1.*" %>
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
String ethApiEndPoint = "https://ropsten.infura.io/v3/1a2cc5dffd8b46699947c7a73d152380";
String senderAddress = "0xEF6046938e7F8508E934d53502957a755EB90315";
String senderPublicKey = "0285AB5095F0F70E0C9118B0DE9764AE96F8773A29DB54235A989E4C06A2165F83";
String toAddress = "65D28726cFA311F80e2C02608185C9900861aad7";

Web3j web3j = Web3j.build(new HttpService(ethApiEndPoint));
EthGetTransactionCount ethGetTransactionCount = web3j.ethGetTransactionCount(
             senderAddress, DefaultBlockParameterName.LATEST).sendAsync().get();

BigInteger nonce = ethGetTransactionCount.getTransactionCount();

Integer chainId = 3;

Transaction tx = new Transaction(
        ByteUtil.bigIntegerToBytes(nonce),
        ByteUtil.longToBytesNoLeadZeroes(20),
        ByteUtil.longToBytesNoLeadZeroes(200000),
        hex2Byte(toAddress),
        ByteUtil.bigIntegerToBytes(BigInteger.valueOf(1)),  // 1 gwei
        null,
        chainId);
byte[] messageHash = tx.getRawHash();
out.println("<p>messageHash=" + byte2Hex(messageHash));
String sSignatureData = "3045022100BE44E2BA2F6095030FBB4D5E459C6CA93C74860B018D142415D7F3B107E2C8C3022004091EFF5742A0CB4799D19379C7EFBDC7F687942341C71E9B60A5432E9A7486";
org.ethereum.crypto.ECKey.ECDSASignature sig = org.ethereum.crypto.ECKey.ECDSASignature.decodeFromDER(hex2Byte(sSignatureData)).toCanonicalised();

org.bitcoinj.core.ECKey pubKey = org.bitcoinj.core.ECKey.fromPublicOnly(hex2Byte(senderPublicKey));
org.bitcoinj.core.ECKey decompressedPubKey = pubKey.decompress();
        // Now we have to work backwards to figure out the recId needed to recover the signature.
        int recId = -1;
        //byte[] thisKey = this.pub.getEncoded(/* compressed */ false);
        byte[] thisKey = decompressedPubKey.getPubKey();
out.println("<p>thisKey= " + byte2Hex(thisKey));
        for (int i = 0; i < 4; i++) {
            byte[] k = recoverPubBytesFromSignature(i, sig, messageHash);
            if (k != null && Arrays.equals(k, thisKey)) {
                recId = i;
                break;
            }
        }
out.println("<p>recId= " + recId);
        //if (recId == -1)
            //throw new RuntimeException("Could not construct a recoverable key. This should never happen.");
        //sig.v = (byte) (recId + 27);


//tx.signature = sig;
//tx.rlpEncoded = null;
//out.println("<p>Raw transaction getEncoded: 0x{}", Hex.encodeHexString(tx.getEncoded()));
//out.println("<p>Raw transaction getEncodedRaw: 0x{}", Hex.encodeHexString(tx.getEncodedRaw()));


/*
ASN1Object o;
		try {
			o = ASN1Object.fromByteArray(hex2Byte(signatureData));
		} catch (Exception e) {
			throw new CryptException("Key is not ASN.1 encoded data.");
		}
ASN1Sequence seq = ASN1Sequence.getInstance(hex2Byte(signatureData));

encodedTransaction = TransactionEncoder.encode(rawTransaction, hex2Byte(signatureData));
String transactionHash = byte2Hex(encodedTransaction);
out.println("<p>signed transactionHash=" + transactionHash);
*/
%>

<%!
/*
    public X9ECParameters CURVE_PARAMS = CustomNamedCurves.getByName("secp256k1");
    final ECDomainParameters CURVE =
            new ECDomainParameters(
                    CURVE_PARAMS.getCurve(),
                    CURVE_PARAMS.getG(),
                    CURVE_PARAMS.getN(),
                    CURVE_PARAMS.getH());
    final BigInteger HALF_CURVE_ORDER = CURVE_PARAMS.getN().shiftRight(1);
*/    
        /**
         * @throws SignatureDecodeException if the signature is unparseable in some way.
         */


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

    /** Decompress a compressed public key (x co-ord and low-bit of y-coord). */
/*
    private static ECPoint decompressKey(BigInteger xBN, boolean yBit) {
        X9IntegerConverter x9 = new X9IntegerConverter();
        byte[] compEnc = x9.integerToBytes(xBN, 1 + x9.getByteLength(CURVE.getCurve()));
        compEnc[0] = (byte) (yBit ? 0x03 : 0x02);
        return CURVE.getCurve().decodePoint(compEnc);
    }
*/

%>