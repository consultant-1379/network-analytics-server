/*
 * COPYRIGHT Ericsson 2017
 * The copyright to the computer program(s) herein is the property of
 * Ericsson Inc. The programs may be used and/or copied only with written
 * permission from Ericsson Inc. or in accordance with the terms and
 * conditions stipulated in the agreement/contract under which the
 * program(s) have been supplied.
 */

package filter;

import com.spotfire.server.security.AuthenticationContext;
import com.spotfire.server.security.CustomAuthenticator;
import com.spotfire.server.security.CustomAuthenticatorException;
import com.spotfire.server.security.CustomAuthenticatorPrincipal;

import javax.naming.NamingEnumeration;
import javax.naming.NamingException;
import javax.naming.directory.DirContext;
import javax.naming.directory.SearchControls;
import javax.naming.directory.SearchResult;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;


public class AuthenticationFilter implements CustomAuthenticator {
    private static final String[] ATTRIBUTES = {"cn", "ou"};
    private static final String CLASS = AuthenticationFilter.class.getName();
    private static final String SSO_TOKEN = "SSO_Token";
    private static final String REFERRER = "Referer";
    private static final String USER_NAME = "Username";
    private static final Logger LOGGER = Logger.getLogger(CLASS);
    private String searchBase;
    private String domainControllerName;
    private String enmServerName;
    private String domainControllerPassword;
    private String ldapURL;
    private String headerSSOToken;
    private String headerUserName;
    private String domainName;

    @Override
    public CustomAuthenticatorPrincipal authenticate(AuthenticationContext authContext) throws CustomAuthenticatorException {

        if (authContext.getHeader(REFERRER) == null && authContext.getHeader(SSO_TOKEN) == null) {
            return null;
        }
        if (authContext.getHeader(REFERRER) != null && !authContext.getHeader(REFERRER).contains(enmServerName)) {
            return null;
        }
        if (authContext.getHeader(SSO_TOKEN) != null) {
            headerSSOToken = authContext.getHeader(SSO_TOKEN);
        }
        if (authContext.getHeader(USER_NAME) != null) {
            headerUserName = authContext.getHeader(USER_NAME);
        }
        if (headerUserName != null && !headerUserName.isEmpty() && headerSSOToken != null && !headerSSOToken.isEmpty()) {
            if (processRequest(headerUserName, headerSSOToken, domainControllerName, domainControllerPassword, ldapURL)) {
                try {
                    return new CustomAuthenticatorPrincipal(headerUserName, domainName, headerUserName, null);

                } catch (Exception e) {
                    LOGGER.log(Level.WARNING, "Authentication Failed for: %s ", headerUserName);
                }
            }
        } else {
            return null;
        }
        throw new CustomAuthenticatorException("Authentication has failed");
    }

    public void init(Map<String, String> parameters) {
        domainControllerName = parameters.get("DOMAIN_CONTROLLER_NAME");
        domainControllerPassword = parameters.get("DOMAIN_CONTROLLER_PASSWORD");
        ldapURL = parameters.get("LDAP_URL");
        domainName = parameters.get("DOMAIN_NAME");
        enmServerName = parameters.get("ENM_SERVER_NAME");
        searchBase = parameters.get("SEARCH_BASE");
    }

    public boolean processRequest(String username, String headerSSOToken, String domainControllerName, String
            domainControllerPassword, String ldapURL) {

        final DirContext ldapAuthenticationContext;

        try {
            ldapAuthenticationContext = Authenticator.getContext(domainControllerName, domainControllerPassword, ldapURL);
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, ("Initial Domain Controller Context Failed"));
            return false;
        }
        SearchControls searchControls = new SearchControls();
        searchControls.setSearchScope(SearchControls.SUBTREE_SCOPE);
        searchControls.setReturningAttributes(ATTRIBUTES);
        NamingEnumeration values = null;

        try {
            String filter = "cn=" + username;
            values = ldapAuthenticationContext.search(searchBase, filter, searchControls);

        } catch (NullPointerException e) {
            LOGGER.log(Level.WARNING, ("Base Search Failed, NullPointerException"));
        } catch (NamingException e) {
            LOGGER.log(Level.WARNING, ("Base Search Failed, NamingException"));
        }

        if (values != null) {
            if (performLdapSearch(headerSSOToken, ldapURL, values)) {
                cleanupContext(ldapAuthenticationContext);
                LOGGER.log(Level.INFO, ("Single Sign On Credentials Authenticated for User: " + username));
                return true;
            } else {
                LOGGER.log(Level.WARNING, ("Single Sign On Credentials not Authenticated"));
                return false;
            }
        }
        cleanupContext(ldapAuthenticationContext);
        LOGGER.log(Level.INFO, "Authentication Failed for user: %s ", username);
        return false;
    }

    private void cleanupContext(DirContext ldapAuthenticationContext) {
        if (ldapAuthenticationContext != null) {
            try {
                ldapAuthenticationContext.close();
            } catch (Exception e) {
                LOGGER.log(Level.WARNING, "Error Closing Context", e);
            }
        }
    }

    private boolean performLdapSearch(String headerSSOToken, String ldapURL, NamingEnumeration values) {
        try {
            final SearchResult result = (SearchResult) values.next();
            final String distinguishedName = result.getNameInNamespace();
            Authenticator.getContext(distinguishedName, headerSSOToken, ldapURL);
            LOGGER.log(Level.INFO, "LDAP Search Succeeded for User: " + headerUserName);
            return true;

        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "LDAP search failed", e);
            return false;
        }
    }

}