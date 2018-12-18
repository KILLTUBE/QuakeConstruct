/*
===========================================================================
Copyright (C) 1999-2005 Id Software, Inc.

This file is part of Quake III Arena source code.

Quake III Arena source code is free software; you can redistribute it
and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of the License,
or (at your option) any later version.

Quake III Arena source code is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Foobar; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
===========================================================================
*/
//
// cg_snapshot.c -- things that happen on snapshot transition,
// not necessarily every single rendered frame

#define	 replayLen 512

#include "cg_local.h"

int recStartTime = 0;
int recPlayTime = 0;
int count = 0;
int playbackFrame = 0;
int	lastCapTime = 0;
snapshot_t replaySnaps[replayLen];
qboolean playBack = qfalse;
qboolean wasPlaying = qfalse;

qboolean replayRunning() {
	return playBack;
}

void recordSnap() {
	snapshot_t snap;
	entityState_t *state;
	int i=0;
	trap_GetSnapshot(cgs.processedSnapshotNum,&snap);
	snap.serverTime -= recStartTime;
	for(i=0; i<snap.numEntities; i++) {
		state = &snap.entities[i];
		if(state->time != 0) state->time -= recStartTime;
		if(state->time2 != 0) state->time2 -= recStartTime;
		state->pos.trTime -= recStartTime;
		state->apos.trTime -= recStartTime;
	}

	if(count < replayLen) {
		CG_Printf("Recorded Snapshot: %i\n", count);
		replaySnaps[count] = snap;
		count++;
	} else {
		CG_Printf("Recorded Snapshot MAX\n");

		//Shift the array back and put a new frame in.

		//memmove( replaySnaps, replaySnaps+1, sizeof( replaySnaps ) -sizeof( replaySnaps[ 0 ] ) );

		/*for(i=0; i<replayLen-1; i++) {
			replaySnaps[i] = replaySnaps[i+1];
		}*/
		replaySnaps[replayLen-1] = snap;
	}
}

/*
==================
CG_ResetEntity
==================
*/
static void CG_ResetEntity( centity_t *cent ) {
	lua_State *L = GetClientLuaState();
	qboolean isplayer = (&cgs.clientinfo[ cent->currentState.clientNum ] != NULL);
	if(L != NULL) {
		//cent->linked = qfalse;
		//qlua_gethook(L,"EntityUnlinked");
		//lua_pushentity(L,cent);
		//qlua_pcall(L,1,0,qtrue);

		if(cent->luatablecent != 0) { // && !isplayer
			qlua_clearfunc(L,cent->luatablecent);
			cent->luatablecent = 0;
		}
	} else {
		if(cent->luatablecent != 0) { // && !isplayer
			cent->luatablecent = 0;
		}
	}
	cent->customdraw = qfalse;

	// if the previous snapshot this entity was updated in is at least
	// an event window back in time then we can reset the previous event
	if ( cent->snapShotTime < cg.time - EVENT_VALID_MSEC || playBack ) {
		cent->previousEvent = 0;
	}

	cent->trailTime = cg.snap->serverTime;

	VectorCopy (cent->currentState.origin, cent->lerpOrigin);
	VectorCopy (cent->currentState.angles, cent->lerpAngles);
	if ( cent->currentState.eType == ET_PLAYER ) {
		CG_ResetPlayerEntity( cent );
	}
}

void firstReplayFrame() {
	int				i;
	snapshot_t		*snap;
	centity_t		*cent;
	entityState_t	*state;
	lua_State		*L = GetClientLuaState();

	snap = &replaySnaps[0];
	cg.snap = snap;
	cg.snap->serverTime += cg.time;

	BG_PlayerStateToEntityState( &snap->ps, &cg_entities[ snap->ps.clientNum ].currentState, qfalse );

	CG_BuildSolidList();
	CG_ExecuteNewServerCommands( snap->serverCommandSequence );
	CG_Respawn();

	for ( i = 0 ; i < sizeof(cg_entities) / sizeof(cg_entities[0]); i++ ) {
		CG_ResetEntity(&cg_entities[i]);
	}

	for ( i = 0 ; i < cg.snap->numEntities ; i++ ) {
		state = &cg.snap->entities[ i ];
		cent = &cg_entities[ state->number ];

		if(state->time != 0) state->time += cg.time;
		if(state->time2 != 0) state->time2 += cg.time;
		state->pos.trTime += cg.time;
		state->apos.trTime += cg.time;

		memcpy(&cent->currentState, state, sizeof(entityState_t));
		cent->interpolate = qtrue;
		cent->currentValid = qtrue;
		CG_ResetEntity( cent );

		CG_CheckEvents( cent );

		cent->previousEvent = 0;
	}

	//cg.time = snap->serverTime;
}

void playReplay() {
	/*playBack = qtrue;
	wasPlaying = qtrue;
	recPlayTime = cg.time;
	firstReplayFrame();
	playbackFrame++;*/
}

snapshot_t *getReplaySnap(int off) {
	if(playbackFrame < replayLen-1) {
		return &replaySnaps[playbackFrame + off];
	} else {
		if(wasPlaying) {
			wasPlaying = qfalse;
			playBack = qfalse;
			playbackFrame = 0;
			count = 0;
			return NULL;
		}
	}
	return cg.snap;
}

/*
===============
CG_TransitionEntity

cent->nextState is moved to cent->currentState and events are fired
===============
*/
static void CG_TransitionEntity( centity_t *cent ) {
	lua_State		*L = GetClientLuaState();
	cent->currentState = cent->nextState;
	cent->currentValid = qtrue;

	// reset if the entity wasn't in the last frame or was teleported
	if ( !cent->interpolate ) {
		CG_ResetEntity( cent );

		if(L != NULL && cent->linked == qfalse && cent->currentState.eType <= ET_LUA && 
			cent->currentState.eType != ET_GENERAL) {
			qlua_gethook(L,"EntityLinked");
			lua_pushentity(L,cent);
			qlua_pcall(L,1,0,qtrue);
			cent->linked = qtrue;
		}
	}

	// clear the next state.  if will be set by the next CG_SetNextSnap
	cent->interpolate = qfalse;

	// check for events
	CG_CheckEvents( cent );
}


/*
==================
CG_SetInitialSnapshot

This will only happen on the very first snapshot, or
on tourney restarts.  All other times will use 
CG_TransitionSnapshot instead.

FIXME: Also called by map_restart?
==================
*/
void CG_SetInitialSnapshot( snapshot_t *snap ) {
	int				i;
	centity_t		*cent;
	entityState_t	*state;
	lua_State		*L = GetClientLuaState();

	cg.snap = snap;

	BG_PlayerStateToEntityState( &snap->ps, &cg_entities[ snap->ps.clientNum ].currentState, qfalse );

	// sort out solid entities
	CG_BuildSolidList();

	CG_ExecuteNewServerCommands( snap->serverCommandSequence );

	// set our local weapon selection pointer to
	// what the server has indicated the current weapon is
	CG_Respawn();

	for ( i = 0 ; i < cg.snap->numEntities ; i++ ) {
		state = &cg.snap->entities[ i ];
		cent = &cg_entities[ state->number ];

		memcpy(&cent->currentState, state, sizeof(entityState_t));
		//cent->currentState = *state;
		cent->interpolate = qfalse;
		cent->currentValid = qtrue;

		CG_ResetEntity( cent );

		// check for events
		CG_CheckEvents( cent );

		if(L != NULL && cent->linked == qfalse && cent->currentState.eType <= ET_LUA && 
			cent->currentState.eType != ET_GENERAL) {
			qlua_gethook(L,"EntityLinked");
			lua_pushentity(L,cent);
			qlua_pcall(L,1,0,qtrue);
			cent->linked = qtrue;
		}
	}

	if(L != NULL && !playBack) {
		qlua_gethook(L,"InitialSnapshot");
		qlua_pcall(L,0,0,qtrue);
	}
}


/*
===================
CG_TransitionSnapshot

The transition point from snap to nextSnap has passed
===================
*/
static void CG_TransitionSnapshot( void ) {
	centity_t			*cent;
	snapshot_t			*oldFrame;
	int					i;

	if ( !cg.snap ) {
		CG_Error( "CG_TransitionSnapshot: NULL cg.snap" );
	}
	if ( !cg.nextSnap ) {
		CG_Error( "CG_TransitionSnapshot: NULL cg.nextSnap" );
	}

	// execute any server string commands before transitioning entities
	CG_ExecuteNewServerCommands( cg.nextSnap->serverCommandSequence );

	// if we had a map_restart, set everthing with initial
	if ( !cg.snap ) {
	}

	// clear the currentValid flag for all entities in the existing snapshot
	for ( i = 0 ; i < cg.snap->numEntities ; i++ ) {
		cent = &cg_entities[ cg.snap->entities[ i ].number ];
		cent->currentValid = qfalse;
	}

	// move nextSnap to snap and do the transitions
	oldFrame = cg.snap;
	cg.snap = cg.nextSnap;

	BG_PlayerStateToEntityState( &cg.snap->ps, &cg_entities[ cg.snap->ps.clientNum ].currentState, qfalse );
	cg_entities[ cg.snap->ps.clientNum ].interpolate = qfalse;

	for ( i = 0 ; i < cg.snap->numEntities ; i++ ) {
		cent = &cg_entities[ cg.snap->entities[ i ].number ];
		CG_TransitionEntity( cent );

		// remember time of snapshot this entity was last updated in
		cent->snapShotTime = cg.snap->serverTime;
	}

	cg.nextSnap = NULL;

	// check for playerstate transition events
	if ( oldFrame ) {
		playerState_t	*ops, *ps;

		ops = &oldFrame->ps;
		ps = &cg.snap->ps;
		// teleporting checks are irrespective of prediction
		if ( ( ps->eFlags ^ ops->eFlags ) & EF_TELEPORT_BIT ) {
			cg.thisFrameTeleport = qtrue;	// will be cleared by prediction code
		}

		// if we are not doing client side movement prediction for any
		// reason, then the client events and view changes will be issued now
		if ( cg.demoPlayback || (cg.snap->ps.pm_flags & PMF_FOLLOW)
			|| cg_nopredict.integer || cg_synchronousClients.integer ) {
			CG_TransitionPlayerState( ps, ops );
		}
	}

}


/*
===================
CG_SetNextSnap

A new snapshot has just been read in from the client system.
===================
*/
static void CG_SetNextSnap( snapshot_t *snap ) {
	lua_State			*L = GetClientLuaState();
	int					num,i,n;
	int					numEnts = sizeof(cg_entities) / sizeof(cg_entities[0]);
	entityState_t		*es;
	centity_t			*cent,*tent;
	qboolean			f = qfalse;
	qboolean			isplayer = qfalse;

	cg.nextSnap = snap;

	BG_PlayerStateToEntityState( &snap->ps, &cg_entities[ snap->ps.clientNum ].nextState, qfalse );
	cg_entities[ cg.snap->ps.clientNum ].interpolate = qtrue;

	// check for extrapolation errors
	for ( num = 0 ; num < snap->numEntities ; num++ ) {
		es = &snap->entities[num];
		cent = &cg_entities[ es->number ];
		isplayer = (&cgs.clientinfo[ cent->currentState.clientNum ] != NULL);

		memcpy(&cent->nextState, es, sizeof(entityState_t));
		//cent->nextState = *es;

		// if this frame is a teleport, or the entity wasn't in the
		// previous frame, don't interpolate
		if ( !cent->currentValid || ( ( cent->currentState.eFlags ^ es->eFlags ) & EF_TELEPORT_BIT )  ) {
			cent->interpolate = qfalse;
		} else {
			cent->interpolate = qtrue;
		}
	}

	if(L != NULL) {
		for (i = 0, tent = cg_entities, n = 1; i < numEnts; i++, tent++) {
			if(tent != NULL && tent->linked) {
				isplayer = (&cgs.clientinfo[ tent->currentState.clientNum ] != NULL);
				f = qfalse;
				for ( num = 0 ; num < snap->numEntities ; num++ ) {
					es = &snap->entities[num];
					if(es->number == tent->currentState.number) {
						f = qtrue;
					}
				}
				// && !isplayer
				if(f == qfalse) {
					tent->linked = qfalse;
					qlua_gethook(L,"EntityUnlinked");
					lua_pushentity(L,tent);
					qlua_pcall(L,1,0,qtrue);
				}
			}
			n++;
		}
	}

	// if the next frame is a teleport for the playerstate, we
	// can't interpolate during demos
	if ( cg.snap && ( ( snap->ps.eFlags ^ cg.snap->ps.eFlags ) & EF_TELEPORT_BIT ) ) {
		cg.nextFrameTeleport = qtrue;
	} else {
		cg.nextFrameTeleport = qfalse;
	}

	// if changing follow mode, don't interpolate
	if ( cg.nextSnap->ps.clientNum != cg.snap->ps.clientNum ) {
		cg.nextFrameTeleport = qtrue;
	}

	// if changing server restarts, don't interpolate
	if ( ( cg.nextSnap->snapFlags ^ cg.snap->snapFlags ) & SNAPFLAG_SERVERCOUNT ) {
		cg.nextFrameTeleport = qtrue;
	}

	// sort out solid entities
	CG_BuildSolidList();
}


/*
========================
CG_ReadNextSnapshot

This is the only place new snapshots are requested
This may increment cgs.processedSnapshotNum multiple
times if the client system fails to return a
valid snapshot.
========================
*/
static snapshot_t *CG_ReadNextSnapshot( void ) {
	qboolean	r;
	snapshot_t	*dest;

	if ( cg.latestSnapshotNum > cgs.processedSnapshotNum + 1000 ) {
		CG_Printf( "WARNING: CG_ReadNextSnapshot: way out of range, %i > %i", 
			cg.latestSnapshotNum, cgs.processedSnapshotNum );
	}

	while ( cgs.processedSnapshotNum < cg.latestSnapshotNum ) {
		// decide which of the two slots to load it into
		if ( cg.snap == &cg.activeSnapshots[0] ) {
			dest = &cg.activeSnapshots[1];
		} else {
			dest = &cg.activeSnapshots[0];
		}

		// try to read the snapshot from the client system
		cgs.processedSnapshotNum++;
		r = trap_GetSnapshot( cgs.processedSnapshotNum, dest );

		// FIXME: why would trap_GetSnapshot return a snapshot with the same server time
		if ( cg.snap && r && dest->serverTime == cg.snap->serverTime ) {
			//continue;
		}

		// if it succeeded, return
		if ( r ) {
			CG_AddLagometerSnapshotInfo( dest );
			return dest;
		}

		// a GetSnapshot will return failure if the snapshot
		// never arrived, or  is so old that its entities
		// have been shoved off the end of the circular
		// buffer in the client system.

		// record as a dropped packet
		CG_AddLagometerSnapshotInfo( NULL );

		// If there are additional snapshots, continue trying to
		// read them.
	}

	// nothing left to read
	return NULL;
}


/*
============
CG_ProcessSnapshots

We are trying to set up a renderable view, so determine
what the simulated time is, and try to get snapshots
both before and after that time if available.

If we don't have a valid cg.snap after exiting this function,
then a 3D game view cannot be rendered.  This should only happen
right after the initial connection.  After cg.snap has been valid
once, it will never turn invalid.

Even if cg.snap is valid, cg.nextSnap may not be, if the snapshot
hasn't arrived yet (it becomes an extrapolating situation instead
of an interpolating one)

============
*/

void CG_ProcessSnapshots( void ) {
	snapshot_t		*snap;
	int				n,i;

	// see what the latest snapshot the client system has is
	trap_GetCurrentSnapshotNumber( &n, &cg.latestSnapshotTime );
	if ( n != cg.latestSnapshotNum ) {
		if ( n < cg.latestSnapshotNum ) {
			// this should never happen
			CG_Error( "CG_ProcessSnapshots: n < cg.latestSnapshotNum" );
		}
		cg.latestSnapshotNum = n;
	}

	// If we have yet to receive a snapshot, check for it.
	// Once we have gotten the first snapshot, cg.snap will
	// always have valid data for the rest of the game
	while ( !cg.snap ) {
		snap = CG_ReadNextSnapshot();
		if ( !snap ) {
			// we can't continue until we get a snapshot
			return;
		}

		// set our weapon selection to what
		// the playerstate is currently using
		if ( !( snap->snapFlags & SNAPFLAG_NOT_ACTIVE ) ) {
			CG_SetInitialSnapshot( snap );
		}
	}

	// loop until we either have a valid nextSnap with a serverTime
	// greater than cg.time to interpolate towards, or we run
	// out of available snapshots
	do {
		// if we don't have a nextframe, try and read a new one in
		if ( !playBack ) {
			if ( !cg.nextSnap ) {
				snap = CG_ReadNextSnapshot();

				// if we still don't have a nextframe, we will just have to
				// extrapolate
				if ( !snap ) {
					break;
				}

				CG_SetNextSnap( snap );


				// if time went backwards, we have a level restart
				if ( cg.nextSnap->serverTime < cg.snap->serverTime ) {
					CG_Error( "CG_ProcessSnapshots: Server time went backwards" );
				}
			}

			// if our time is < nextFrame's, we have a nice interpolating state
			if ( cg.time >= cg.snap->serverTime && cg.time < cg.nextSnap->serverTime ) {
				break;
			}
		}

		// we have passed the transition from nextFrame to frame
		/*if(playBack) {
			snap = getReplaySnap(0);
			if(snap != NULL) {
				snap->serverTime += recPlayTime;
				for(i=0; i<snap->numEntities; i++) {
					if(snap->entities[i].time != 0) snap->entities[i].time += recPlayTime;
					if(snap->entities[i].time2 != 0) snap->entities[i].time2 += recPlayTime;
					snap->entities[i].pos.trTime += recPlayTime;
					snap->entities[i].apos.trTime += recPlayTime;
				}

				CG_SetNextSnap(snap);
				CG_Printf("Transition: %i > %i\n",cg.snap->serverTime,snap->serverTime);
				CG_TransitionSnapshot();

				playbackFrame++;
				return;
			} else {
				cg.snap = NULL;
				cg.nextSnap = NULL;
				CG_ProcessSnapshots();
				return;
			}
		} else {
			if(cg.nextSnap->serverTime != lastCapTime) {
				recordSnap();
				lastCapTime = cg.nextSnap->serverTime;
			}
		}*/
		CG_TransitionSnapshot();
	} while ( 1 );
	// assert our valid conditions upon exiting
	if ( cg.snap == NULL ) {
		CG_Error( "CG_ProcessSnapshots: cg.snap == NULL" );
	}
	if ( cg.time < cg.snap->serverTime ) {
		// this can happen right after a vid_restart
		cg.time = cg.snap->serverTime;
	}
	if ( cg.nextSnap != NULL && cg.nextSnap->serverTime <= cg.time ) {
		CG_Error( "CG_ProcessSnapshots: cg.nextSnap->serverTime <= cg.time" );
	}

}

