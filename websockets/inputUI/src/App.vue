<template>
	<div>

		

	</div>	
</template>

<script>

export default {
	mounted(){
		var query = window.location.href
		let len = query.split('/').length
		let it = this
		let namespacedPodName = query.split('/')[len-1]
		this.podName = namespacedPodName.split('_')[1]
		this.namespace = namespacedPodName.split('_')[0]
		console.log("/////////////////////")
		console.log(namespacedPodName)
		console.log(this.podName)
			console.log("/////////////////////")
		this.randID = Math.random().toString(36).slice(-6);
		this.axios
		.get('/api/podlog',  {params: {namespace: it.namespace , podName: it.podName, randID:it.randID}})
		.then(response => {
			console.log(response.data)
		})
		

		let randSid = Math.random().toString(36).slice(-6);

		console.log(this.podName)
		//let url = "ws://192.168.3.221:5678/basic-web-6c5bc79ccd-7w8fc_"+str 
		let url = "ws://192.168.2.221:5678/" + this.namespace +"_" + this.podName + "_"+ this.randID  +"_" + randSid
		//let url = "ws://192.168.3.221:5678/basic"
		console.log(url)
		let ws = new WebSocket(url)
		ws.onmessage = function(event) {
			var entry
			entry =document.createElement('p')
			entry.textContent= event.data
			document.body.appendChild(entry)
			console.log(event)
		}
		
	},
	
	data(){
		return {
				msg:  '',
				namespace: '',
				podName: '',
				randID:''
		}
	}
	
}

</script>

<style>
</style>
