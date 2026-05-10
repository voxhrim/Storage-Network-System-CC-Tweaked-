# Storage-Network-System-CC-Tweaked- v 1.0
Wireless storage monitor for ComputerCraft


============================================================
					SETUP
============================================================


You need complete 3 steps:

1) Install Storage Computer
2) Install Main Server Computer
3) Install Display Computer


============================================================
			1. STORAGE COMPUTER
============================================================

	Figure:

		 [ Ender Modem ] (back)
					|
			[ Computer ]
					|
			[ Wired Modem ]
					|
			   [ Storage ]


	You can use:
	- chest
	- barrel
	- drawer
	- modded storage
	- any storage compatible with ComputerCraft


	Installation:

	Copy all files from:
		Storage comp/
	to the storage computer 
	(save/world name/computercraft/computer/'id'/)
	
	If the desired 'id' isn't in the computer folder
	create an empty program (edit test) and save it. The computer will 
	then appear in the folder.

	Configuration:

	Open:
		config.lua
	You can change:

	- storage ID
	- storage label 
	- update interval


============================================================
		   2. MAIN SERVER COMPUTER
============================================================

	Figure:

		 [ Ender Modem ] (back)
					|
			[ Server Computer ]


	Installation:

	Copy all files from:
		Server comp/
	to the server computer.


============================================================
			 3. DISPLAY COMPUTER
============================================================

	Figure:

		 [ Advanced Monitor ]
					|
			[ Display Computer ]
					|
			 [ Ender Modem ] (back)


	IMPORTANT:
	The monitor must be directly connected
	to the display computer.


	Installation:

	Copy all files from:
		Display comp/
	to the display computer.


============================================================
				USAGE
============================================================


	The display has 4 pages:


	------------------------------------------------------------
	1) DASHBOARD
	------------------------------------------------------------

		Quick overview of the network:

		- total items
		- active nodes
		- network load


	------------------------------------------------------------
	2) NODES
	------------------------------------------------------------

		Shows all connected storage nodes
		and their storage usage (%).


	------------------------------------------------------------
	3) ITEMS
	------------------------------------------------------------

		Global list of ALL items
		in the whole network.


		Controls:
			Upper half click  -> scroll up
			Lower half click  -> scroll down


	------------------------------------------------------------
	4) INVENTORY
	------------------------------------------------------------

		Shows inventory of selected storage node.


		Controls:
			Left side click   -> previous storage
			Right side click  -> next storage
			Upper half click  -> scroll up
			Lower half click  -> scroll down


============================================================
			      NOTES
============================================================


	When adding a new storage node,
	it is recommended to restart:
	- server computer
	- display computer

	Usually the system updates automatically,
	but restart guarantees correct detection.


============================================================
			  RECOMMENDED
============================================================

	Recommended update interval:

		UPDATE_INTERVAL >= 1

	Lower values:
	- faster updates
	- higher server load


