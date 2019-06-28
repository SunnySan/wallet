<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>

<%@ page import="java.security.Security" %>
<%@ page import="javax.crypto.Cipher" %>
<%@ page import="javax.crypto.SecretKey" %>
<%@ page import="javax.crypto.spec.IvParameterSpec" %>
<%@ page import="javax.crypto.spec.SecretKeySpec" %>

<%@ page import="sun.misc.BASE64Encoder" %>
<%@ page import="sun.misc.BASE64Decoder" %>

<%@ page import="java.security.MessageDigest" %>
<%@ page import="java.security.NoSuchAlgorithmException" %>

<%@ page import="java.math.BigInteger" %>

<%!

private static final String Algorithm = "DESede"; //定義加密算法,可用 DES,DESede,Blowfish
private static final byte [] ivArr = {(byte) 0x00, (byte) 0x00, (byte) 0x00, (byte) 0x00, (byte) 0x00, (byte) 0x00, (byte) 0x00, (byte) 0x00 };

//將字串加密
public static String encryptString(byte[] keybyte, String src){
	//keybyte為加密密鑰，長度為24字節
	//src為需被加密的原始明文字串
	if (src==null || src.length()<1) return "";
	byte[] byteEncrypted = encryptMode(keybyte, src.getBytes());	//加密
	if (byteEncrypted==null) return "";	//當加解密有誤時會回覆空字串，若原始字串有值，但加解密後變成空的，就需顯示錯誤訊息
	//String newString = bytesToStringUTFCustom(byteEncrypted);	//將 byte array 轉成一個個 char 的字串
	String newString = byte2Hex(byteEncrypted);	//取得 byte array 每個 byte 的 16 進位碼
	return newString;
}

//將字串解密
public static String decryptString(byte[] keybyte, String src){
	//keybyte為加密密鑰，長度為24字節
	//src為需被解密的已加密字串
	if (src==null || src.length()<1) return "";
	//byte[] byteStr = stringToBytesUTFCustom(src);	//將一個個 char 的字串轉成 byte array
	byte[] byteStr = hex2Byte(src);	//將 16 進位碼的字串轉為 byte array
	byte[] byteDecrypted = decryptMode(keybyte, byteStr);	//解密
	if (byteDecrypted==null) return "";	//當加解密有誤時會回覆空字串，若原始字串有值，但加解密後變成空的，就需顯示錯誤訊息
	String newString = new String(byteDecrypted);
	return newString;
}

//keybyte為加密密鑰，長度為24字節
//src為被加密的數據緩衝區（源）
public static byte[] encryptMode(byte[] keybyte,byte[] src){
	try {	//生成密鑰
		SecretKey deskey = new SecretKeySpec(keybyte, Algorithm);
		//加密
		Cipher c1 = Cipher.getInstance(Algorithm+"/CBC/NoPadding");
		IvParameterSpec iv = new IvParameterSpec(ivArr);
		c1.init(Cipher.ENCRYPT_MODE, deskey, iv);
		return c1.doFinal(src);//在單一方面的加密或解密
	} catch (java.security.NoSuchAlgorithmException e1) {
		// TODO: handle exception
		e1.printStackTrace();
	}catch(javax.crypto.NoSuchPaddingException e2){
		e2.printStackTrace();
	}catch(java.lang.Exception e3){
		e3.printStackTrace();
	}
	return null;
}

//keybyte為加密密鑰，長度為24字節
//src為加密後的緩衝區
public static byte[] decryptMode(byte[] keybyte,byte[] src){
	try {
		//生成密鑰
		SecretKey deskey = new SecretKeySpec(keybyte, Algorithm);
		//解密
		Cipher c1 = Cipher.getInstance(Algorithm+"/CBC/NoPadding");
		IvParameterSpec iv = new IvParameterSpec(ivArr);
		c1.init(Cipher.DECRYPT_MODE, deskey, iv);
		return c1.doFinal(src);
	} catch (java.security.NoSuchAlgorithmException e1) {
		// TODO: handle exception
		e1.printStackTrace();
	}catch(javax.crypto.NoSuchPaddingException e2){
		e2.printStackTrace();
	}catch(java.lang.Exception e3){
		e3.printStackTrace();
	}
	return null;
}

/*
//轉換成十六進製字符串
public static String byte2Hex(byte[] b){
	String hs="";
	String stmp="";
	for(int n=0; n<b.length; n++){
		stmp = (java.lang.Integer.toHexString(b[n]& 0XFF));
		if(stmp.length()==1){
			hs = hs + "0" + stmp;
		}else{
			hs = hs + stmp;
		}
		if(n<b.length-1)hs=hs+":";
	}
	return hs.toUpperCase();
}
*/

//取得 byte array 每個 byte 的 16 進位碼
public static String byte2Hex(byte[] b) {
	String result = "";
	for (int i=0 ; i<b.length ; i++)
		result += Integer.toString( ( b[i] & 0xff ) + 0x100, 16).substring( 1 );
	return result;
}


//取得字串的 16 進位碼
public static String string2Hex(String plainText, String charset) throws UnsupportedEncodingException {
	return String.format("%040x", new BigInteger(1, plainText.getBytes(charset)));
}


//將 16 進位碼的字串轉為 byte array
public static byte[] hex2Byte(String hexString) {
	byte[] bytes = new byte[hexString.length() / 2];
	for (int i=0 ; i<bytes.length ; i++)
		bytes[i] = (byte) Integer.parseInt(hexString.substring(2 * i, 2 * i + 2), 16);
	return bytes;
}

/*
//將 16 進位碼字串還原成原始文字
public static String hex2String(String hexString) {
	StringBuilder str = new StringBuilder();
	for (int i=0 ; i<hexString.length() ; i+=2)
		str.append((char) Integer.parseInt(hexString.substring(i, i + 2), 16));
	return str.toString();
}
*/


//將 byte array 轉成一個個 char 的字串
public static String bytesToStringUTFCustom(byte[] bytes) {
	char[] buffer = new char[bytes.length >> 1];
	for(int i = 0; i < buffer.length; i++) {
		int bpos = i << 1;
		char c = (char)(((bytes[bpos]&0x00FF)<<8) + (bytes[bpos+1]&0x00FF));
		buffer[i] = c;
	}
	return new String(buffer);
}

//將一個個 char 的字串轉成 byte array
public static byte[] stringToBytesUTFCustom(String str) {
	char[] buffer = str.toCharArray();
	byte[] b = new byte[buffer.length << 1];
	for(int i = 0; i < buffer.length; i++) {
		int bpos = i << 1;
		b[bpos] = (byte) ((buffer[i]&0xFF00)>>8);
		b[bpos + 1] = (byte) (buffer[i]&0x00FF);
	}
	return b;
}

public static String BASE64Encode(String s) {
	if (s == null) return null;
	return (new sun.misc.BASE64Encoder()).encode( s.getBytes() );
}

public static String BASE64Encode(byte[] s) {
	if (s == null) return null;
	return (new sun.misc.BASE64Encoder()).encode( s );
}

public static String BASE64EncodeHex(String s) {
	if (s == null) return null;
	return (new sun.misc.BASE64Encoder()).encode( hex2Byte(s) );
}

public static String BASE64Decode(String s) {
	if (s == null) return null;
	BASE64Decoder decoder = new sun.misc.BASE64Decoder();
	try {
		byte[] b = decoder.decodeBuffer(s);
		return new String(b);
	} catch (Exception e) {
		return null;
	}
}

public static String BASE64DecodeHex(String s) {
	if (s == null) return null;
	BASE64Decoder decoder = new sun.misc.BASE64Decoder();
	try {
		byte[] b = decoder.decodeBuffer(s);
		return byte2Hex(b);
	} catch (Exception e) {
		return null;
	}
}

public static String MD5Encode(String plainText) {
	StringBuffer hexString = new StringBuffer();
	try{
		MessageDigest mdAlgorithm = MessageDigest.getInstance("MD5");
		mdAlgorithm.update(plainText.getBytes());
		byte[] digest = mdAlgorithm.digest();
		for (int i = 0; i < digest.length; i++) {
			plainText = Integer.toHexString(0xFF & digest[i]);
			if (plainText.length() < 2) {
				plainText = "0" + plainText;
			}
			hexString.append(plainText);
		}
	}catch (NoSuchAlgorithmException e){
		return "";
	}
	return hexString.toString();
}

//對兩個 byte array 做 XOR 運算
public static byte[] byteXor(byte[] array_1, byte[] array_2){
	byte[] array_3 = new byte[array_1.length];
	for (int i = 0; i < array_3.length; i++) {
		array_3[i] = (byte) (((int) array_1[i]) ^ ((int) array_2[i]));
	}
	return array_3;
}
%>