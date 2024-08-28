/*
 * COPYRIGHT Ericsson 2017
 * The copyright to the computer program(s) herein is the property of
 * Ericsson Inc. The programs may be used and/or copied only with written
 * permission from Ericsson Inc. or in accordance with the terms and
 * conditions stipulated in the agreement/contract under which the
 * program(s) have been supplied.
 */

package filter;

import javax.naming.Context;
import javax.naming.NamingException;
import javax.naming.directory.DirContext;
import javax.naming.directory.InitialDirContext;
import java.util.Hashtable;

public class Authenticator {

    private Authenticator() {
    }

    public static DirContext getContext(String username, String password, String ldapURL) throws NamingException {
        final Hashtable<String, Object> envVars = new Hashtable<String, Object>();
        envVars.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
        envVars.put(Context.PROVIDER_URL, ldapURL);
        envVars.put(Context.SECURITY_AUTHENTICATION, "simple");
        envVars.put(Context.REFERRAL, "ignore");
        envVars.put(Context.SECURITY_PRINCIPAL, username);
        envVars.put(Context.SECURITY_CREDENTIALS, password);
        return new InitialDirContext(envVars);
    }
}