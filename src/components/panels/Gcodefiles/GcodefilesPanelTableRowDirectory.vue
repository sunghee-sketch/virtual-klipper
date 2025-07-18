<template>
    <tr
        v-longpress:600="showContextMenuAction"
        :class="trClasses"
        draggable="true"
        @click="goToDirectory"
        @contextmenu="showContextMenuAction($event)"
        @dragenter.prevent="isHover = true"
        @dragleave.prevent="isHover = false"
        @drop="onDrop"
        @dragover="onDragOver"
        @dragstart="onDragStart"
        @drag="onDrag">
        <td class="file-list__select-td pr-0">
            <v-simple-checkbox v-ripple :value="isSelected" class="pa-0 mr-0" @click.stop="select(!isSelected)" />
        </td>
        <td class="px-0 text-center" style="width: 32px">
            <v-icon>{{ mdiFolder }}</v-icon>
        </td>
        <td class=" " :colspan="tableColumns.length + 2">{{ item.filename }}</td>
        <v-menu
            v-model="showContextMenu"
            :position-x="showContextMenuX"
            :position-y="showContextMenuY"
            absolute
            offset-y>
            <v-list>
                <v-list-item @click="showRenameDirectoryDialog = true">
                    <v-icon class="mr-1">{{ mdiRenameBox }}</v-icon>
                    {{ $t('Files.Rename') }}
                </v-list-item>
                <v-list-item class="red--text" @click="showDeleteDirectoryDialog = true">
                    <v-icon class="mr-1" color="error">{{ mdiDelete }}</v-icon>
                    {{ $t('Files.Delete') }}
                </v-list-item>
            </v-list>
        </v-menu>
        <gcodefiles-rename-directory-dialog
            :item="item"
            :show-dialog="showRenameDirectoryDialog"
            @close="showRenameDirectoryDialog = false" />
        <gcodefiles-delete-directory-dialog
            :item="item"
            :show-dialog="showDeleteDirectoryDialog"
            @close="showDeleteDirectoryDialog = false" />
    </tr>
</template>
<script lang="ts">
import { Component, Mixins, Prop } from 'vue-property-decorator'
import BaseMixin from '@/components/mixins/base'
import GcodefilesMixin from '@/components/mixins/gcodefiles'
import { FileStateGcodefile } from '@/store/files/types'
import { mdiDelete, mdiFolder, mdiRenameBox } from '@mdi/js'

@Component
export default class GcodefilesPanelTableRowDirectory extends Mixins(BaseMixin, GcodefilesMixin) {
    mdiDelete = mdiDelete
    mdiFolder = mdiFolder
    mdiRenameBox = mdiRenameBox

    showContextMenu = false
    showContextMenuX = 0
    showContextMenuY = 0

    showRenameDirectoryDialog = false
    showDeleteDirectoryDialog = false

    isHover = false

    @Prop({ type: Object, required: true }) readonly item!: FileStateGcodefile
    @Prop({ type: Boolean, required: true }) readonly isSelected!: boolean
    @Prop({ type: Function, required: true }) readonly select!: Function

    get trClasses() {
        return {
            'file-list-cursor': true,
            'user-select-none': true,
            'file-list-row-hover': this.isHover,
        }
    }

    showContextMenuAction(e: MouseEvent) {
        if (this.showContextMenu) return

        e?.preventDefault()
        this.showContextMenuX = e?.clientX || e?.pageX || window.screenX / 2
        this.showContextMenuY = e?.clientY || e?.pageY || window.screenY / 2

        this.$nextTick(() => {
            this.showContextMenu = true
        })
    }

    goToDirectory() {
        this.currentPath += '/' + this.item.filename
    }

    onDrop(e: DragEvent) {
        e.preventDefault()
        this.isHover = false

        const dragFilename = e.dataTransfer?.getData('filename')

        const source = [this.currentPath, dragFilename].join('/')
        const dest = [this.currentPath, this.item.filename, dragFilename].join('/')

        this.$socket.emit(
            'server.files.move',
            {
                source: 'gcodes' + source,
                dest: 'gcodes' + dest,
            },
            { action: 'files/getMove' }
        )
    }

    // this function is important to disable the browser default function to activate the onDrop function
    onDragOver(e: DragEvent) {
        e.preventDefault()
    }

    onDragStart(e: DragEvent) {
        if (e.dataTransfer === null) return

        e.dataTransfer.setData('filename', this.item.filename)
        e.dataTransfer.effectAllowed = 'move'
    }

    onDrag(e: DragEvent) {
        e.preventDefault()
        e.stopPropagation()
    }
}
</script>

<style scoped>
.file-list-row-hover {
    background-color: #43a04720;
}
</style>
