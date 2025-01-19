/*
 *  antiPiracy.c
 *  RacingTach
 *
 *  Created by Gérald GUIONY on 30/03/11.
 *  Copyright 2011 Gérald GUIONY. All rights reserved.
 *
 */

#include "AntiPiracy.h"

#include <stdio.h>
#include <unistd.h>

#define DISTRIBUTION_VERSION 0
//#define DISTRIBUTION_VERSION 1

static bool _threadActive = false;

// ====================================================================================================================================
// http://www.iphonedevsdk.com/forum/iphone-sdk-tutorials/36330-iphone-piracy-protection-code-2-another-tutorial.html
// ====================================================================================================================================

// ------------------------------------------------------------------------------------------------------------------------------------
/*
This code is very self explanatory. We are checking to make sure the user is not the iPhone Simulator, we're grabbing the process id,
and checking to make sure it's not the root. Basically, whenever someone cracks your application, some automated processes run it as
root in order to run gdb. We are simply making sure that user is not the root. This problem with this method is that the app does not
have to be run as root, therefore many cracking applications can be adjusted around this.
*/
// ------------------------------------------------------------------------------------------------------------------------------------
bool userIsNotRoot (void)
{
#if !DISTRIBUTION_VERSION
	printf("userIsNotRoot() ?\n");
#endif

#if !TARGET_IPHONE_SIMULATOR
	int root = getgid();
	return (root > 10);  // Pirated si root <= 10
#endif
	return true;
}

// ====================================================================================================================================

#include <dlfcn.h>

// The iPhone SDK doesn't have, but it does have ptrace, and it works just fine.
typedef int (*ptrace_ptr_t) (int _request, pid_t _pid, caddr_t _addr, int _data);
#if !defined(PT_DENY_ATTACH)
#define  PT_DENY_ATTACH  31
#endif  // !defined(PT_DENY_ATTACH)

// ------------------------------------------------------------------------------------------------------------------------------------
/*
In a nutshell we're just checking to see if the debugger is attached to your application, and if it is, stopping the debugger. In order
to crack an application you have to attach a debugger to it, stop it, and dump it from the memory. If you stop the debugger then you've
cut the head from the snake.
*/
// ------------------------------------------------------------------------------------------------------------------------------------
bool checkDebugIntegrity (void)
{
#if !DISTRIBUTION_VERSION
	printf("checkDebugIntegrity()\n");
#endif

	// If all assertions are enabled, we're in a legitimate debug build.
#if TARGET_IPHONE_SIMULATOR || defined(DEBUG) || (!defined(NS_BLOCK_ASSERTIONS) && !defined(NDEBUG))
	return true;
#endif

	// Lame obfuscation of the string "ptrace".
	char ptrace_root [100] = {'\0'};
	// socket
	sprintf (ptrace_root, "%s%s%s", "so", "cke", "t");

	char ptrace_name[] = {0xfd, 0x05, 0x0f, 0xf6, 0xfe, 0xf1, 0x00};

	for (size_t i = 0; i < sizeof(ptrace_name); i++)
	{
		ptrace_name[i] += ptrace_root[i];
	}

	void * handle = dlopen (0, RTLD_GLOBAL | RTLD_NOW);
	ptrace_ptr_t ptrace_ptr = dlsym (handle, ptrace_name);
	ptrace_ptr (PT_DENY_ATTACH, 0, 0, 0);
	dlclose (handle);

	return false;
}


// ====================================================================================================================================

#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <TargetConditionals.h>

/* The encryption info struct and constants are missing from the iPhoneSimulator SDK, but not from the iPhoneOS or
 * Mac OS X SDKs. Since one doesn't ever ship a Simulator binary, we'll just provide the definitions here. */
#if TARGET_IPHONE_SIMULATOR && !defined(LC_ENCRYPTION_INFO)
#define LC_ENCRYPTION_INFO 0x21
struct encryption_info_command {
    uint32_t cmd;
    uint32_t cmdsize;
    uint32_t cryptoff;
    uint32_t cryptsize;
    uint32_t cryptid;
};
#endif

// La méthode d'entrée de l'appli
extern int main (int argc, char *argv[]);

// ------------------------------------------------------------------------------------------------------------------------------------
// http://landonf.bikemonkey.org/code/iphone/iPhone_Preventing_Piracy.20090213.html
/*
 On the phone, purchased applications are shipped to the user with a variety of meta-data that is readable by the application. The
 information potentially useful for implementing additional copy protection includes:

 iTunesMetadata.plist - Media & Purchase Information (incl user's name, Apple ID, and purchase date)
 SC_Info - FairPlay DRM Metadata
 Code Signing - Binaries and resources are encrypted and signed by Apple

 Using this information, it is possible to implement additional copy protection. The signature can be checked, the application encryption
 can be verified, etc. However, there's a problem -- none of this is documented by Apple. While most of the APIs and file formats are
 public, the actual distribution format is not. Apple could change the signature format, the meta-data plist, or any other distribution
 component at any time, at which point your copy protection may raise a false positive, and your paying customers will be wondering why
 you're wasting their time.

 The current process of cracking an application relies on stripping the application of encryption by attaching a debugger to the
 application on a jailbroken phone, dumping the text section containing the program code, and reinserting it into the original binary.
 The below code checks for the existence of LC_ENCRYPTION_INFO, and verifies that encryption is still enabled.
*/
// ------------------------------------------------------------------------------------------------------------------------------------
bool isEncrypted (void)
{
#if !DISTRIBUTION_VERSION
	printf("isEncrypted() ?\n");
#endif

    const struct mach_header *header;
    Dl_info dlinfo;

    /* Fetch the dlinfo for main() */
    if (dladdr(main, &dlinfo) == 0 || dlinfo.dli_fbase == NULL)
	{
#if !DISTRIBUTION_VERSION
        printf("Impossible de trouver la méthode d'entrée du programme !\n");
#endif
        return false;
    }
    header = dlinfo.dli_fbase;

    /* Compute the image size and search for a UUID */
    struct load_command *cmd = (struct load_command *) (header+1);

    for (uint32_t i = 0; (cmd != NULL) && (cmd->cmd != LC_ENCRYPTION_INFO) && (i < header->ncmds); i++)
	{
		cmd = (struct load_command *) ((uint8_t *) cmd + cmd->cmdsize);
    }

	/* Encryption info segment */
	if (cmd->cmd == LC_ENCRYPTION_INFO)
	{
		struct encryption_info_command *crypt_cmd = (struct encryption_info_command *) cmd;

		/* Check if binary encryption is enabled */
		if (crypt_cmd->cryptid >= 1)
		{
#if !DISTRIBUTION_VERSION
			printf("Encryption is enabled !\n");
#endif
			/* Probably not pirated? */
			return true;
		}
		else
		{
#if !DISTRIBUTION_VERSION
			// Report an error.
			printf("Encryption is disabled !\n");
			return true;
#else
			/* Disabled, probably pirated */
			return false;
#endif
		}
	}

#if !DISTRIBUTION_VERSION
	// Report an error.
	printf("Encryption info not found !\n");
	return true;
#else
    /* Encryption info not found */
    return false;
#endif
}

// ====================================================================================================================================


#include <stdlib.h>
#include <time.h>
#include <notify.h>

#include <assert.h>
#include <pthread.h>

// ------------------------------------------------------------------------------------------------------------------------------------
// Retourne un entier random compris entre min et max-1
// ------------------------------------------------------------------------------------------------------------------------------------
int randomInt (int min, int max)
{
static bool randomInitialized = false;

	if (!randomInitialized)
	{
		srand(time(NULL)); // Une fois suffit
		randomInitialized = true;
	}

	return ((rand() % (max-min)) + min);
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Méthode appelée par le nouveau thread
// ------------------------------------------------------------------------------------------------------------------------------------
typedef void (* punish_func) (void *);
// Nombre de méthodes de détection du piratage
#define NB_PUNISH_FUNC	7
// Tableau de pointeur de fonctions sur les méthodes de détection du piratage
punish_func PunishFunctionsList [NB_PUNISH_FUNC] = {	(punish_func) exit,
														(punish_func) close,
														(punish_func) reboot,
														(punish_func) reboot,
														(punish_func) system,
														(punish_func) system,
														(punish_func) notify_post	};

void * punishThreadRoutine (void * data)
{
	void * ptr = NULL;
	char param [100] = {'\0'};

	// Timer
	sleepThreadRoutine (data);

    // Random sur la sanction (tableau des méthodes de sanctions)
	int punishId = randomInt (0, NB_PUNISH_FUNC);

	/*
	 exit(0);
	 close(0);
	 reboot(0);
	 reboot(RB_HALT);
	 system("reboot");
	 system("killall SpringBoard");
	 notify_post("com.apple.language.changed");

	 //[[UIApplication sharedApplication] terminate];
	 */

	if (punishId == 3)
	{
		// RB_HALT
		ptr = (void *)0x08;
	}
	else if (punishId == 4)
	{
		// reboot
		sprintf (param, "%s%s%s", "r", "ebo", "ot");
		ptr = (void *)param;
	}
	else if (punishId == 5)
	{
		// killall SpringBoard
		sprintf (param, "%s%s %s%s%s", "k", "illall", "Spr", "in", "gBoard");
		ptr = (void *)param;
	}
	else if (punishId == 6)
	{
		// com.apple.language.changed
		sprintf (param, "%s%s%s%s%s", "co", "m.app", "le.lang", "uage.ch", "anged");
		ptr = (void *)param;
	}

#if !DISTRIBUTION_VERSION
	printf("Punish %d\n", punishId);
#endif

	// Appel de la méthode
	(*(PunishFunctionsList[punishId]))(ptr);

    return NULL;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Timer
// ------------------------------------------------------------------------------------------------------------------------------------
void * sleepThreadRoutine (void * data)
{
	// Random sur le delay d'attente en seconde
	sleep(randomInt (5, 10)); // Entre 5 et 10s

	// Mis à jour du flag indiquant qque le thread est lancé
	_threadActive = false;

	return NULL;
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Be aware that Cocoa needs to know that you want to do multi-threading. It is important to first detach a dummy NSThread so the
// application can be considered multi-threaded
// ------------------------------------------------------------------------------------------------------------------------------------
void launchThread (void *(* routine)(void *))
{
    // Create the thread using POSIX routines.
    pthread_attr_t  attr;
    pthread_t       posixThreadID;
    int             returnVal;

	// Because POSIX creates threads as joinable by default, this example changes the thread’s attributes to create a detached thread.
	// Marking the thread as detached gives the system a chance to reclaim the resources for that thread immediately when it exits.
    returnVal = pthread_attr_init (&attr);
    assert (!returnVal);
    returnVal = pthread_attr_setdetachstate (&attr, PTHREAD_CREATE_DETACHED);
    assert (!returnVal);

    int threadError = pthread_create (&posixThreadID, &attr, routine, NULL);

    returnVal = pthread_attr_destroy (&attr);
    assert (!returnVal);

    if (threadError != 0)
    {
#if !DISTRIBUTION_VERSION
         // Report an error.
		 printf("Erreur : impossible de créer le thread détaché !");
#endif
    }
}

// ------------------------------------------------------------------------------------------------------------------------------------
// Contrôle du piratage
// ------------------------------------------------------------------------------------------------------------------------------------

// Nombre de méthodes de détection du piratage
#define NB_CHECK_PIRACY_FUNC	3
// Tableau de pointeur de fonctions sur les méthodes de détection du piratage
bool (*CheckPiracyFunctionsList[NB_CHECK_PIRACY_FUNC]) (void) = {	userIsNotRoot		,
																	checkDebugIntegrity	,
																	isEncrypted			};

void checkPiracy ()
{
	if (_threadActive) return;
	_threadActive = true;

	// Random sur la méthode de contrôle (tableau de pointeur sur les méthodes)
	if (!(*(CheckPiracyFunctionsList[randomInt (0, NB_CHECK_PIRACY_FUNC)]))())
//	if ((*(CheckPiracyFunctionsList[randomInt (0, NB_CHECK_PIRACY_FUNC)]))())
	{
#if !DISTRIBUTION_VERSION
		// Report an error.
		printf("Pirated !\n");
#endif

		// Si version piratée lancement d'un timer qui ferme l'application ou qui empéche de la redemarrer ...
		launchThread (&punishThreadRoutine);
		return;
	}

	// Lancement d'un timer
	launchThread (&sleepThreadRoutine);

#if !DISTRIBUTION_VERSION
	printf("Not pirated ...\n");
#endif
}


