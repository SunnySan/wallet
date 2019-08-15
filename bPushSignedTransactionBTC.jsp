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

String cardId			= nullToString(request.getParameter("cardId"), "");
String signature		= nullToString(request.getParameter("data"), "");
String transactionId	= nullToString(request.getParameter("transactionId"), "");

if ((beEmpty(cardId) && beEmpty(signature) && beEmpty(transactionId)) || (beEmpty(transactionId) && ((beEmpty(cardId) && notEmpty(signature))||(notEmpty(cardId) && beEmpty(signature))))){
	writeLog("debug", "BIP push signed BTC/BTETEST transaction parameter not found for Card_Id= " + cardId + ", signature= " + signature + ", transactionId= " + transactionId);
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
	return;
}else{
	writeLog("debug", "BIP push signed BTC/BTETEST transaction for Card_Id= " + cardId + ", signature= " + signature + ", transactionId= " + transactionId);
}

Hashtable	ht					= new Hashtable();
String		sResultCode			= gcResultCodeSuccess;
String		sResultText			= gcResultTextSuccess;
String		s[][]				= null;
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
URL			u;
String		sUrl				= "";
String		sData				= "";

sSQL = "SELECT A.id, B.id, B.Currency_Id, B.Unsigned_Hex, C.Address, C.Publicy_Key, A.Transaction_Id";
sSQL += " FROM cwallet_bip_job_queue A, cwallet_transaction B, cwallet_wallet_currency C";
if (notEmpty(transactionId)){
	sSQL += " WHERE A.Transaction_Id='" + transactionId + "'";
}else{
	sSQL += " WHERE A.Card_Id='" + cardId + "'";
	sSQL += " AND A.Status='" + "Sync" + "'";
}
sSQL += " AND A.CMD='" + "50" + "'";
sSQL += " AND A.Transaction_Id=B.Transaction_Id";
sSQL += " AND C.Card_Id=B.Card_Id";
sSQL += " AND C.Wallet_Id=B.Wallet_Id";
sSQL += " AND C.Currency_Id=B.Currency_Id";
sSQL += " ORDER BY A.id desc";
sSQL += " LIMIT 1";

ht = getDBData(sSQL, gcDataSourceNameCMSIOT);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s = (String[][])ht.get("Data");
	jobRowId = s[0][0];
	transactionRowId = s[0][1];
	currencyId = s[0][2];
	unsignedHash = s[0][3];
	address = s[0][4];
	publicKey = s[0][5];
	transactionId = s[0][6];
	writeLog("debug", "transactionId= " + transactionId);

	sSQL = "SELECT Signed_Hex FROM cwallet_transaction_hash";
	sSQL += " WHERE Transaction_Id='" + transactionId + "'";
	sSQL += " ORDER BY Hash_Index";
	ht = getDBData(sSQL, gcDataSourceNameCMSIOT);
	
	sResultCode = ht.get("ResultCode").toString();
	sResultText = ht.get("ResultText").toString();
	if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
		s = (String[][])ht.get("Data");
		writeLog("debug", "Signature count= " + String.valueOf(s.length));
	}else{
		writeLog("error", "BIP query BTC/BTCTEST transaction signature failed, transactionId= " + transactionId + ", sResultCode= " + sResultCode + ", sResultText= " + sResultText);
		obj.put("resultCode", sResultCode);
		obj.put("resultText", sResultText);
		out.print(obj);
		out.flush();
		return;
	}
	
	NetworkParameters params = null;
	if (currencyId.equals("BTC")) params = NetworkParameters.fromID(NetworkParameters.ID_MAINNET);
	else params = NetworkParameters.fromID(NetworkParameters.ID_TESTNET);
	
	Transaction tx = new Transaction(params, hex2Byte(unsignedHash));
	
	if (tx.getInputs().size()!=s.length){	//未簽名資料中，需簽名的hash個數和DB中的signature個數不同
		writeLog("error", "BIP BTC/BTCTEST transaction signature count failed, transactionId= " + transactionId + ", there are " + String.valueOf(tx.getInputs().size()) + " hash(s) in the unsigned data, we hava " + s.length + " signatures.");
		obj.put("resultCode", gcResultCodeNoDataFound);
		obj.put("resultText", "Fail, signature count not match the hash count.");
		out.print(obj);
		out.flush();
		return;
	}
	
	writeLog("debug", "Starting injecting signature(s) to the unsigned BTC/BTCTEST raw transaction");
	for (i = 0; i < tx.getInputs().size(); i++) {
		TransactionInput transactionInput = tx.getInput(i);
		Script scriptPubKey = ScriptBuilder.createOutputScript(Address.fromString(params, address));
		
		if (beEmpty(s[i][0])){
			writeLog("error", "BIP BTC/BTCTEST transaction, one or more signature is empty. transactionId= " + transactionId);
			obj.put("resultCode", gcResultCodeNoDataFound);
			obj.put("resultText", "Fail, signature count not match the hash count.");
			out.print(obj);
			out.flush();
			return;
		}

		ECKey.ECDSASignature sig1 = ECKey.ECDSASignature.decodeFromDER(hex2Byte(s[i][0]));
		sig1 = sig1.toCanonicalised();
		
		TransactionSignature txSig = null;
		
		txSig = new TransactionSignature(sig1, Transaction.SigHash.ALL, true);
	
		if (scriptPubKey.isSentToRawPubKey()) {
			transactionInput.setScriptSig(ScriptBuilder.createInputScript(txSig));
		} else {
			if (!scriptPubKey.isSentToAddress()) {
				writeLog("error", "Don't know how to sign for this kind of scriptPubKey: " + scriptPubKey + ", transactionId= " + transactionId);
				sResultCode = gcResultCodeUnknownError;
				sResultText = "Don't know how to sign for this kind of scriptPubKey";
				obj.put("resultCode", sResultCode);
				obj.put("resultText", sResultText);
				out.print(obj);
				out.flush();
				return;
			}
			transactionInput.setScriptSig(ScriptBuilder.createInputScript(txSig, ECKey.fromPublicOnly(hex2Byte(publicKey))));
		}
	}
	tx.verify();
	valueToSend = byte2Hex(tx.bitcoinSerialize());

	sUrl = "";
	/*
	if (currencyId.equals("BTC")){
		sUrl = "https://chain.so/api/v2/send_tx/BTC";
	}else{
		sUrl = "https://chain.so/api/v2/send_tx/BTCTEST";
	}
	*/
	if (currencyId.equals("BTC")){
		sUrl = "https://blockchain.info/pushtx";
	}else{
		sUrl = "https://testnet.blockchain.info/pushtx";
	}
	
	//sData = "tx_hex=" + valueToSend;
	sData = "tx=" + valueToSend;
	
	try
	{
		writeLog("debug", "Send BTC/BTCTEST transaction hex to " + sUrl + ", data= " + sData);
	
		String urlParameters  = sData;
		byte[] postData       = urlParameters.getBytes( StandardCharsets.UTF_8 );
		int    postDataLength = postData.length;
	
		u = new URL(sUrl);
		HttpURLConnection uc = (HttpURLConnection)u.openConnection();
		uc.setRequestProperty( "Content-Type", "application/x-www-form-urlencoded"); 
		//uc.setRequestProperty( "charset", "utf-8");
		uc.setRequestProperty( "Content-Length", Integer.toString( postDataLength ));
		uc.setUseCaches( false );
		uc.setRequestMethod("POST");
		uc.setDoOutput(true);
		uc.setDoInput(true);
	
	
		uc.setRequestProperty("User-agent", "Mozilla/5.0 (Windows; U; Windows NT 6.0; zh-TW; rv:1.9.1.2) " + "Gecko/20090729 Firefox/3.5.2 GTB5 (.NET CLR 3.5.30729)"); 
		uc.setRequestProperty("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"); 
		uc.setRequestProperty("Accept-Language", "zh-tw,en-us;q=0.7,en;q=0.3"); 
		uc.setRequestProperty("Accept-Charse", "Big5,utf-8;q=0.7,*;q=0.7"); 
		//uc.setRequestProperty("Content-Length", sData.getBytes().length); 
	
		try( DataOutputStream wr = new DataOutputStream( uc.getOutputStream())) {
			wr.write( postData );
		}
		
	
		InputStream in = uc.getInputStream();
		BufferedReader r = new BufferedReader(new InputStreamReader(in));
		StringBuffer buf = new StringBuffer();
		String line;
		while ((line = r.readLine())!=null) {
			buf.append(line);
		}
		in.close();
		sResponse = buf.toString();	//取得回應值
		writeLog("debug", "sResponse: " + sResponse);
		if (notEmpty(sResponse) && sResponse.equals("Transaction Submitted")){
			sResultCode = gcResultCodeSuccess;
			sResultText = gcResultTextSuccess;
			txid = sResponse;
			bOK = true;
			/*
			//解析JSON參數
			JSONParser parser = new JSONParser();
			Object objBody = parser.parse(sResponse);
			JSONObject jsonObjectBody = (JSONObject) objBody;
			ss = (String) jsonObjectBody.get("status");
			if (beEmpty(ss) || !ss.equals("success")){
				writeLog("error", sUrl + " doesn't reply success. It replies [ " + ss + " ]");
				sResultCode = gcResultCodeUnknownError;
				sResultText = ss;
			}else{
				objBody = jsonObjectBody.get("data");
				jsonObjectBody = (JSONObject) objBody;
				txid = (String) jsonObjectBody.get("txid");
				bOK = true;
				writeLog("info", sUrl + " replies success.");
			}
			*/
		}else{
			writeLog("error", sUrl + " doesn't reply anything.");
			sResultCode = gcResultCodeUnknownError;
			sResultText = gcResultTextUnknownError;
		}
	}catch (IOException e){
		sResponse = e.toString();
		writeLog("error", "Exception when broadcast BTC/BTCTEST transaction to chain: " + e.toString());
		sResultCode = gcResultCodeUnknownError;
		//sResultText = sResponse;
		sResultText = "Fail, unable to broadcast transaction to chain.";
	}

}else{
	writeLog("error", "BIP query signed BTC/BTCTEST transaction data failed, SQL= " + sSQL + ", sResultCode= " + sResultCode + ", sResultText= " + sResultText);
	obj.put("resultCode", sResultCode);
	obj.put("resultText", sResultText);
	out.print(obj);
	out.flush();
	return;
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

writeLog("debug", "Going to change transaction status in DB.");
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

