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
<%@page import="org.web3j.crypto.Hash" %>
<%@page import="org.web3j.crypto.Sign" %>
<%@page import="org.web3j.crypto.Sign.*" %>
<%@page import="org.web3j.crypto.ECDSASignature" %>
<%@page import="org.web3j.crypto.RawTransaction" %>
<%@page import="org.web3j.utils.Numeric" %>
<%@page import="org.web3j.rlp.RlpEncoder" %>
<%@page import="org.web3j.rlp.RlpList" %>
<%@page import="org.web3j.rlp.RlpString" %>
<%@page import="org.web3j.rlp.RlpType" %>


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
Web3j web3j = Web3j.build(new HttpService(ethApiEndPoint));
EthGetTransactionCount ethGetTransactionCount = web3j.ethGetTransactionCount(
             senderAddress, DefaultBlockParameterName.LATEST).sendAsync().get();

BigInteger nonce = ethGetTransactionCount.getTransactionCount();

BigInteger gasPrice = BigInteger.valueOf(20);	//Gwei
BigInteger gasLimit = BigInteger.valueOf(21000);
String to = "0x65D28726cFA311F80e2C02608185C9900861aad7";
BigInteger value = BigInteger.valueOf(1);

RawTransaction rawTransaction  = RawTransaction.createEtherTransaction(nonce, gasPrice, gasLimit, to, value);
byte[] encodedTransaction = TransactionEncoder.encode(rawTransaction);
byte[] messageHash = Hash.sha3(encodedTransaction);	//須被簽名的資料
out.println("<p>messageHash=" + byte2Hex(messageHash));
String sSignatureData = "3045022100BE44E2BA2F6095030FBB4D5E459C6CA93C74860B018D142415D7F3B107E2C8C3022004091EFF5742A0CB4799D19379C7EFBDC7F687942341C71E9B60A5432E9A7486";

ECDSASignature sig = decodeFromDER(hex2Byte(sSignatureData));
sig = sig.toCanonicalised();
BigInteger publicKey = Numeric.toBigInt(hex2Byte(senderPublicKey));
out.println("<p>publicKey=" + publicKey + "<p>");
        // Now we have to work backwards to figure out the recId needed to recover the signature.
        int recId = -1;
        for (int i = 0; i < 4; i++) {
            BigInteger k = Sign.recoverFromSignature(i, sig, messageHash);
            out.println(i +"=" + k);
            if (k != null && k.equals(publicKey)) {
                recId = i;
                break;
            }
        }
        if (recId == -1) {
        	return;
            //throw new RuntimeException("Could not construct a recoverable key. Are your credentials valid?");
        }

        int headerByte = recId + 27;

        // 1 header + 32 bytes for R + 32 bytes for S
        byte[] v = new byte[] {(byte) headerByte};
        byte[] r = Numeric.toBytesPadded(sig.r, 32);
        byte[] s = Numeric.toBytesPadded(sig.s, 32);

        Sign.SignatureData signatureData = new SignatureData(v, r, s);

        List<RlpType> values = TransactionEncoder.asRlpValues(rawTransaction, signatureData);
        RlpList rlpList = new RlpList(values);
        encodedTransaction = RlpEncoder.encode(rlpList);
//encodedTransaction = TransactionEncoder.encode(rawTransaction, signatureData);
String transactionHash = byte2Hex(encodedTransaction);
out.println("<p>signed transactionHash=" + transactionHash);

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
        public ECDSASignature decodeFromDER(byte[] bytes) {
            ASN1InputStream decoder = null;
            try {
                // BouncyCastle by default is strict about parsing ASN.1 integers. We relax this check, because some
                // Bitcoin signatures would not parse.
                decoder = new ASN1InputStream(bytes);
                final ASN1Primitive seqObj = decoder.readObject();
                if (seqObj == null)
                    return null;
                if (!(seqObj instanceof DLSequence))
                    return null;
                final DLSequence seq = (DLSequence) seqObj;
                ASN1Integer r, s;
                try {
                    r = (ASN1Integer) seq.getObjectAt(0);
                    s = (ASN1Integer) seq.getObjectAt(1);
                } catch (ClassCastException e) {
                    return null;
                }
                // OpenSSL deviates from the DER spec by interpreting these values as unsigned, though they should not be
                // Thus, we always use the positive versions. See: http://r6.ca/blog/20111119T211504Z.html
                return new ECDSASignature(r.getPositiveValue(), s.getPositiveValue());
            } catch (IOException e) {
                return null;
            } finally {
                if (decoder != null)
                    try { decoder.close(); } catch (IOException x) {}
            }
        }

/*
    public BigInteger recoverFromSignature(int recId, ECDSASignature sig, byte[] message) {
        if(!(recId >= 0)) return null;;
        if(!(sig.r.signum() >= 0)) return null;;
        if(!(sig.s.signum() >= 0)) return null;;
        if(!(message != null)) return null;;

        // 1.0 For j from 0 to h   (h == recId here and the loop is outside this function)
        //   1.1 Let x = r + jn
        BigInteger n = CURVE.getN(); // Curve order.
        BigInteger i = BigInteger.valueOf((long) recId / 2);
        BigInteger x = sig.r.add(i.multiply(n));
        //   1.2. Convert the integer x to an octet string X of length mlen using the conversion
        //        routine specified in Section 2.3.7, where mlen = ⌈(log2 p)/8⌉ or mlen = ⌈m/8⌉.
        //   1.3. Convert the octet string (16 set binary digits)||X to an elliptic curve point R
        //        using the conversion routine specified in Section 2.3.4. If this conversion
        //        routine outputs "invalid", then do another iteration of Step 1.
        //
        // More concisely, what these points mean is to use X as a compressed public key.
        BigInteger prime = SecP256K1Curve.q;
        if (x.compareTo(prime) >= 0) {
            // Cannot have point co-ordinates larger than this as everything takes place modulo Q.
            return null;
        }
        // Compressed keys require you to know an extra bit of data about the y-coord as there are
        // two possibilities. So it's encoded in the recId.
        ECPoint R = decompressKey(x, (recId & 1) == 1);
        //   1.4. If nR != point at infinity, then do another iteration of Step 1 (callers
        //        responsibility).
        if (!R.multiply(n).isInfinity()) {
            return null;
        }
        //   1.5. Compute e from M using Steps 2 and 3 of ECDSA signature verification.
        BigInteger e = new BigInteger(1, message);
        //   1.6. For k from 1 to 2 do the following.   (loop is outside this function via
        //        iterating recId)
        //   1.6.1. Compute a candidate public key as:
        //               Q = mi(r) * (sR - eG)
        //
        // Where mi(x) is the modular multiplicative inverse. We transform this into the following:
        //               Q = (mi(r) * s ** R) + (mi(r) * -e ** G)
        // Where -e is the modular additive inverse of e, that is z such that z + e = 0 (mod n).
        // In the above equation ** is point multiplication and + is point addition (the EC group
        // operator).
        //
        // We can find the additive inverse by subtracting e from zero then taking the mod. For
        // example the additive inverse of 3 modulo 11 is 8 because 3 + 8 mod 11 = 0, and
        // -3 mod 11 = 8.
        BigInteger eInv = BigInteger.ZERO.subtract(e).mod(n);
        BigInteger rInv = sig.r.modInverse(n);
        BigInteger srInv = rInv.multiply(sig.s).mod(n);
        BigInteger eInvrInv = rInv.multiply(eInv).mod(n);
        ECPoint q = ECAlgorithms.sumOfTwoMultiplies(CURVE.getG(), eInvrInv, R, srInv);

        byte[] qBytes = q.getEncoded(false);
        // We remove the prefix
        return new BigInteger(1, Arrays.copyOfRange(qBytes, 1, qBytes.length));
    }
*/

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