#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define NUMBER_OF_FIELDS 9

static char *userJSON = NULL;
static char *distJSON = NULL;
static char *contextJSON = NULL;
static char *environmentJSON = NULL;
static char *tagsJSON = NULL;
static char *extrasJSON = NULL;
static char *fingerprintJSON = NULL;
static char *levelJSON = NULL;

static long maxCrumbs = 0;
static int currentCrumb = 0;
static char **breadcrumbs = NULL; // dynamic array of char arrays
static const char *breadcrumbsStart = "\"breadcrumbs\":[";

static void
add(char *destination, const char *source)
{
    if (source) {
        strcat(destination, source);
        strcat(destination, ",");
    }
}

static size_t
getSize(const char *str)
{
    size_t size = 0;
    if (str != NULL) {
        size = strlen(str);
    }
    return size;
}

static size_t
getRawBreadcrumbSize(void)
{
    size_t addionitalChars = 3;
    return sizeof(breadcrumbsStart) + maxCrumbs + addionitalChars + 1;
}

/**
 * Returns the required size to serialize the breadcrumbs.
 */
static size_t
getBreadcrumbSize(void)
{
    size_t size = getRawBreadcrumbSize();
    for (int i = 0; i < maxCrumbs; i++) {
        size += getSize(breadcrumbs[i]);
    }
    return size;
}

/**
 * We don't lock access to the properties in this method as this is called when a crash occurs.
 */
char *
sentryscopesync_getJSON(void)
{
    size_t brackets = 2;
    size_t nullByte = 1;
    size_t breadcrumbSize = getBreadcrumbSize();

    size_t resultSize = getSize(userJSON) + getSize(distJSON) + getSize(contextJSON)
        + getSize(environmentJSON) + getSize(tagsJSON) + getSize(extrasJSON)
        + getSize(fingerprintJSON) + getSize(levelJSON) + breadcrumbSize + NUMBER_OF_FIELDS
        + brackets + nullByte;

    if (resultSize == NUMBER_OF_FIELDS + brackets + nullByte + getRawBreadcrumbSize()) {
        // All fields are empty
        return NULL;
    }

    char *result = calloc(1, resultSize); // TODO: fix this

    strcat(result, "{");
    add(result, userJSON);
    add(result, distJSON);
    add(result, contextJSON);
    add(result, environmentJSON);
    add(result, tagsJSON);
    add(result, extrasJSON);
    add(result, fingerprintJSON);
    add(result, levelJSON);

    // No crumbs nothing to add
    if (breadcrumbSize != getRawBreadcrumbSize()) {

        char *crumbs = malloc(breadcrumbSize);

        strcat(crumbs, breadcrumbsStart);
        for (int i = 0; i < maxCrumbs; i++) {
            if (breadcrumbs[i] != NULL) {
                strcat(crumbs, "{");
                strcat(crumbs, breadcrumbs[i]);
                strcat(crumbs, "},");
            }
        }

        size_t crumbLength = strlen(crumbs);
        crumbs[crumbLength - 1] = ']';
        crumbs[crumbLength] = '\0';
        strcat(crumbs, ",");
        strcat(result, crumbs);

        free(crumbs);
    }

    size_t length = strlen(result);
    result[length - 1] = '}';
    result[length] = '\0';

    return result;
}

static void
set(const char *const newJSON, char **field)
{
    char *localField = *field;
    *field = NULL;
    if (localField != NULL) {
        free((void *)localField);
    }

    if (newJSON != NULL) {
        *field = strdup(newJSON);
    }
}

void
sentryscopesync_setUser(const char *const json)
{
    set(json, &userJSON);
}

void
sentryscopesync_setDist(const char *const json)
{
    set(json, &distJSON);
}

void
sentryscopesync_setContext(const char *const json)
{
    set(json, &contextJSON);
}

void
sentryscopesync_setEnvironment(const char *const json)
{
    set(json, &environmentJSON);
}

void
sentryscopesync_setTags(const char *const json)
{
    set(json, &tagsJSON);
}

void
sentryscopesync_setExtras(const char *const json)
{
    set(json, &extrasJSON);
}

void
sentryscopesync_setFingerprint(const char *const json)
{
    set(json, &fingerprintJSON);
}

void
sentryscopesync_setLevel(const char *const json)
{
    set(json, &levelJSON);
}

void
sentryscopesync_addBreadcrumb(const char *const json)
{
    if (!breadcrumbs) {
        return; // TODO: add test
    }

    set(json, &breadcrumbs[currentCrumb]);
    // Ring buffer
    currentCrumb = (currentCrumb + 1) % maxCrumbs;
}

void
sentryscopesync_clearBreadcrumbs(void)
{
    for (int i = 0; i < maxCrumbs; i++) {
        set(NULL, &breadcrumbs[i]);
    }
}

void
sentryscopesync_configureBreadcrumbs(long maxBreadcrumbs)
{
    maxCrumbs = maxBreadcrumbs;
    size_t size = sizeof(char *) * maxCrumbs;
    currentCrumb = 0; // TODO: add test
    if (breadcrumbs) {
        free((void *)*breadcrumbs);
    }
    breadcrumbs = malloc(size);
    memset(breadcrumbs, 0, size);
}

void
sentryscopesync_clear(void)
{
    sentryscopesync_setUser(NULL);
    sentryscopesync_setDist(NULL);
    sentryscopesync_setContext(NULL);
    sentryscopesync_setEnvironment(NULL);
    sentryscopesync_setTags(NULL);
    sentryscopesync_setExtras(NULL);
    sentryscopesync_setFingerprint(NULL);
    sentryscopesync_setLevel(NULL);
    sentryscopesync_clearBreadcrumbs();
}
